defmodule Bugsnag do
  use Application
  require Logger

  def start(_type, _args) do
    config = load_config()

    if use_logger?(config) do
      :error_logger.add_report_handler(Bugsnag.Logger)
    end

    # Update Application config with evaluated configuration
    # It's needed for use in Bugsnag.Payload
    Enum.each(config, fn {k, v} ->
      Application.put_env(:bugsnag, k, v)
    end)

    if is_nil(config[:api_key]) and reported_stage?() do
      Logger.warn("Bugsnag api_key is not configured, errors will not be reported")
    end

    children = [
      {Task.Supervisor, name: Bugsnag.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Bugsnag.Supervisor)
  end

  @doc """
  Report the exception without waiting for the result of the Bugsnag API call.

  (i.e. this might fail silently)
  """
  @spec report(exception :: term(), stacktrace :: Exception.stacktrace(), opts :: list()) ::
          {:ok, pid()} | {:error, :cannot_start_task}
  defdelegate report(exception, stacktrace, opts \\ []), to: Bugsnag.Reporter

  @doc "Report the exception and wait for the result. Returns `:ok` or `{:error, reason}`."
  @spec sync_report(exception :: term(), stacktrace :: Exception.stacktrace(), opts :: list()) ::
          :ok | {:error, reason :: term()}
  defdelegate sync_report(exception, stacktrace, opts \\ []), to: Bugsnag.Reporter

  defp reported_stage?() do
    release_stage = Application.get_env(:bugsnag, :release_stage)
    notify_stages = Application.get_env(:bugsnag, :notify_release_stages)
    release_stage && is_list(notify_stages) && Enum.member?(notify_stages, release_stage)
  end

  defp load_config do
    default_config()
    |> Keyword.merge(Application.get_all_env(:bugsnag))
    |> Enum.map(fn {k, v} -> {k, eval_config(v)} end)
    |> Keyword.update!(:notify_release_stages, fn stages ->
      if(is_binary(stages), do: String.split(stages, ","), else: stages)
    end)
  end

  defp default_config do
    [
      api_key: {:system, "BUGSNAG_API_KEY", nil},
      endpoint_url: {:system, "BUGSNAG_ENDPOINT_URL", "https://notify.bugsnag.com"},
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

  defp use_logger?(config) do
    not is_nil(config[:api_key]) and to_string(config[:use_logger]) == "true"
  end
end
