if function_exported?(Kernel, :is_exception, 1) do
  defmodule Bugsnag.LoggerBackend.GuardShim do
  end
else
  defmodule Bugsnag.LoggerBackend.GuardShim do
    defmacro is_exception(term) do
      quote do
        is_map_key(unquote(term), :__exception__)
      end
    end
  end
end

defmodule Bugsnag.LoggerBackend do
  require Logger

  import Bugsnag.LoggerBackend.GuardShim

  @behaviour :gen_event

  @impl :gen_event
  def init(__MODULE__) do
    {:ok, []}
  end

  @impl :gen_event
  def handle_call({:configure, new_options}, options) do
    {:ok, :ok, Keyword.merge(options, new_options)}
  end

  @impl :gen_event
  def handle_event({_level, _group_leader, {Logger, _message, _timestamp, metadata}}, options) do
    try do
      case metadata[:crash_reason] do
        {{:nocatch, _term}, _stacktrace} ->
          {:ok, options}

        {exception, stacktrace} when is_exception(exception) ->
          Bugsnag.sync_report(exception, stacktrace: stacktrace)
          {:ok, options}

        {_exit_value, _stacktrace} ->
          {:ok, options}

        nil ->
          {:ok, options}
      end
    rescue
      exception ->
        error_message = Exception.format(:error, exception)
        Logger.warn("Unable to notify Bugsnag. #{error_message}")
    end
  end

  def handle_event(_, options) do
    {:ok, options}
  end
end
