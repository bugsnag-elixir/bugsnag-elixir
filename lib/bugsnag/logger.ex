defmodule Bugsnag.Logger do
  require Bugsnag
  require Logger

  use GenEvent

  def init(_mod, []), do: {:ok, []}

  def handle_call({:configure, new_keys}, _state) do
    {:ok, :ok, new_keys}
  end

  def handle_event({_level, gl, _event}, state)
  when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({:error_report, _gl, {_pid, _type, [message | _]}}, state)
  when is_list(message) do
    try do
      error_info = message[:error_info]

      case error_info do
        {_kind, {exception, stacktrace}, _stack} when is_list(stacktrace) ->
          Bugsnag.report(exception, stacktrace: stacktrace)
        {_kind, exception, stacktrace} ->
          Bugsnag.report(exception, stacktrace: stacktrace)
      end
    rescue
      ex ->
        error_type = Exception.normalize(:error, ex).__struct__
                      |> Atom.to_string
                      |> String.replace(~r{\AElixir\.}, "")

        reason = Exception.message(ex)

        Logger.warn "Unable to notify Bugsnag #{error_type}: #{reason}"
    end

    {:ok, state}
  end

  def handle_event({_level, _gl, _event}, state) do
    {:ok, state}
  end
end
