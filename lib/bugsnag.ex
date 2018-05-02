defmodule Bugsnag do
  use Application
  import Supervisor.Spec
  require Logger

  alias Bugsnag.Payload

  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start(_type, _args) do
    config =
      default_config()
      |> Keyword.merge(Application.get_all_env(:bugsnag))
      |> Enum.map(fn {k, v} -> {k, eval_config(v)} end)

    if to_string(config[:use_logger]) == "true" do
      :error_logger.add_report_handler(Bugsnag.Logger)
    end

    # Update Application config with evaluated configuration
    # It's needed for use in Bugsnag.Payload, could be removed
    # by using GenServer instead of this kind of app.
    Enum.each(config, fn {k, v} ->
      Application.put_env(:bugsnag, k, v)
    end)

    if !config[:api_key] and should_notify() do
      Logger.warn("Bugsnag api_key is not configured, errors will not be reported")
    end

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
    Task.Supervisor.start_child(Bugsnag.TaskSupervisor, __MODULE__, :sync_report, [
      exception,
      add_stacktrace(options)
    ])
  end

  defp add_stacktrace(options) when is_list(options) do
    Keyword.put_new(options, :stacktrace, System.stacktrace())
  end

  defp add_stacktrace(options), do: options

  @doc "Report the exception and wait for the result. Returns `ok` or `{:error, reason}`."
  def sync_report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace()

    if should_notify() do
      if Application.get_env(:bugsnag, :api_key) do
        Payload.new(exception, stacktrace, options)
        |> Poison.encode!()
        |> send_notification
        |> case do
          {:ok, %{status_code: 200}} -> :ok
          {:ok, %{status_code: other}} -> {:error, "status_#{other}"}
          {:error, %{reason: reason}} -> {:error, reason}
          _ -> {:error, :unknown}
        end
      else
        Logger.warn("Bugsnag api_key is not configured, error not reported")
        {:error, %{reason: "API key is not configured"}}
      end
    else
      {:ok, :not_sent}
    end
  end

  defp send_notification(body) do
    HTTPoison.post(notify_url(), body, @request_headers)
  end

  def should_notify do
    release_stage = Application.get_env(:bugsnag, :release_stage)
    notify_stages = Application.get_env(:bugsnag, :notify_release_stages)

    release_stage && is_list(notify_stages) && Enum.member?(notify_stages, release_stage)
  end

  defp default_config do
    [
      api_key: {:system, "BUGSNAG_API_KEY", nil},
      endpoint_url: {:system, "BUGSNAG_ENDPOINT_URL", @notify_url},
      use_logger: {:system, "BUGSNAG_USE_LOGGER", true},
      release_stage: {:system, "BUGSNAG_RELEASE_STAGE", "production"},
      notify_release_stages: {:system, "BUGSNAG_NOTIFY_RELEASE_STAGES", ["production"]},
      hostname: {:system, "BUGSNAG_HOSTNAME", "unknown"},
      app_type: {:system, "BUGSNAG_APP_TYPE", "elixir"},
      app_version: {:system, "BUGSNAG_APP_VERSION", nil},
      in_project: {:system, "BUGSNAG_IN_PROJECT", nil}
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

  defp notify_url do
    Application.get_env(:bugsnag, :endpoint_url, @notify_url)
  end
end
