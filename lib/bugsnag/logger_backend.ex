defmodule Bugsnag.LoggerBackend do
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
  def handle_event({_level, _group_leader, {Logger, message, timestamp, metadata}}, options) do
    if Keyword.has_key?(metadata, :crash_reason) do
      case metadata[:crash_reason] do
        {{:nocatch, _term}, _stacktrace} ->
          {:ok, options}

        {exception, stacktrace} when is_exception(exception) ->
          Bugsnag.report(exception, stacktrace: stacktrace)

        {_exit, stacktrace} ->
          {:ok, options}
      end
    else
      {:ok, options}
    end
  end

  def handle_event(_, options) do
    {:ok, options}
  end
end
