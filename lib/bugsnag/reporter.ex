defmodule Bugsnag.Reporter do
  @moduledoc false

  alias Bugsnag.Payload
  require Logger

  @default_notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  @doc """
  Report the exception without waiting for the result of the Bugsnag API call.
  """
  @spec report(exception :: term(), opts :: list()) :: {:ok, pid()} | {:error, :cannot_start_task}
  def report(exception, options \\ []) do
    start_task =
      Task.Supervisor.start_child(
        Bugsnag.TaskSupervisor,
        __MODULE__,
        :sync_report,
        [
          exception,
          add_stacktrace(options)
        ],
        restart: :transient
      )

    case start_task do
      {:ok, pid} -> {:ok, pid}
      _otherwise -> {:error, :cannot_start_task}
    end
  end

  def sync_report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace()

    if should_notify(exception, stacktrace) do
      if Application.get_env(:bugsnag, :api_key) do
        exception
        |> Payload.new(stacktrace, options)
        |> Payload.encode()
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

  defp notify_url do
    Application.get_env(:bugsnag, :endpoint_url, @default_notify_url)
  end

  def should_notify(exception, stacktrace) do
    reported_stage?() && test_filter(exception_filter(), exception, stacktrace)
  end

  defp reported_stage?() do
    release_stage = Application.get_env(:bugsnag, :release_stage)
    notify_stages = Application.get_env(:bugsnag, :notify_release_stages)
    release_stage && is_list(notify_stages) && Enum.member?(notify_stages, release_stage)
  end

  defp exception_filter() do
    Application.get_env(:bugsnag, :exception_filter)
  end

  defp test_filter(nil, _, _), do: true

  defp test_filter(module, exception, stacktrace) do
    try do
      module.should_notify(exception, stacktrace)
    rescue
      _ ->
        # Swallowing error in order to avoid exception loops
        true
    end
  end

  defp add_stacktrace(options) do
    if options[:stacktrace], do: options, else: put_in(options[:stacktrace], System.stacktrace())
  end
end
