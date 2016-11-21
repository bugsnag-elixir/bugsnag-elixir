defmodule Bugsnag do
  use Application
  import Supervisor.Spec

  alias Bugsnag.Payload

  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start(_type, _args) do
    config = Keyword.merge default_config, Application.get_all_env(:bugsnag)

    if config[:use_logger] do
      :error_logger.add_report_handler(Bugsnag.Logger)
    end

    # put normalized api key to application config
    Application.put_env(:bugsnag, :api_key, config[:api_key])

    children = [
      supervisor(Task.Supervisor, [[name: Bugsnag.TaskSupervisor, restart: :transient]])
    ]

    opts = [strategy: :one_for_one, name: Bugsnag.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def report(exception, options \\ []) do
    Task.Supervisor.start_child(
      Bugsnag.TaskSupervisor,
      __MODULE__,
      :send_report,
      [exception, options]
    )
  end

  def send_report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace

    Payload.new(exception, stacktrace, options)
    |> to_json
    |> send_notification
  end


  def to_json(payload) do
    payload |> Poison.encode!
  end

  defp send_notification(body) do
    HTTPoison.post @notify_url, body, @request_headers
  end

  defp default_config do
    [
      api_key: System.get_env("BUGSNAG_API_KEY") || "FAKEKEY",
      use_logger: true
    ]
  end
end
