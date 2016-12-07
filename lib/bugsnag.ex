defmodule Bugsnag do
  use Application
  import Supervisor.Spec

  alias Bugsnag.Payload

  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start(_type, _args) do
    config = default_config
    |> Keyword.merge(Application.get_all_env(:bugsnag))
    |> Enum.map(fn {k, v} -> {k, eval_config(v)} end)

    case config[:use_logger] |> to_string do
      "true" -> :error_logger.add_report_handler(Bugsnag.Logger)
    end

    # Update Application config with evaluated configuration
    # It's needed for use in Bugsnag.Payload, could be removed
    # by using GenServer instead of this kind of app.
    Enum.each config, fn {k, v} ->
      Application.put_env :bugsnag, k, v
    end

    # put normalized api key to application config
    Application.put_env(:bugsnag, :api_key, config[:api_key])

    children = [
      supervisor(Task.Supervisor, [[name: Bugsnag.TaskSupervisor, restart: :transient]])
    ]

    opts = [strategy: :one_for_one, name: Bugsnag.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Report the exception without waiting for the result of the Bugsnag API call.
  (I.e. this might fail silently)
  """
  def report(exception, options \\ []) do
    Task.Supervisor.start_child(
      Bugsnag.TaskSupervisor,
      __MODULE__,
      :sync_report,
      [exception, add_stacktrace(options)]
    )
  end

  defp add_stacktrace(options) when is_list(options) do
    Keyword.put_new(options, :stacktrace, System.stacktrace)
  end
  defp add_stacktrace(options), do: options

  @doc "Report the exception and wait for the result. Returns `ok` or `{:error, reason}`."
  def sync_report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace

    Payload.new(exception, stacktrace, options)
    |> to_json
    |> send_notification
    |> case do
      {:ok, %{status_code: 200}}   -> :ok
      {:ok, %{status_code: other}} -> {:error, "status_#{other}"}
      {:error, %{reason: reason}}  -> {:error, reason}
      _                            -> {:error, :unknown}
    end
  end


  def to_json(payload) do
    payload |> Poison.encode!
  end

  defp send_notification(body) do
    HTTPoison.post(@notify_url, body, @request_headers)
  end

  defp default_config do
    [
      api_key:       {:system, "BUGSNAG_API_KEY", "FAKEKEY"},
      use_logger:    {:system, "BUGSNAG_USE_LOGGER", true},
      release_stage: {:system, "BUGSNAG_RELEASE_STAGE", "test"}
    ]
  end

  defp eval_config({:system, env_var, default}) do
    case System.get_env(env_var) do
      nil -> default
      val -> val
    end
  end

  defp eval_config({:system, env_var}) do
    eval_config({:system, env_var, nil})
  end

  defp eval_config(value), do: value
end
