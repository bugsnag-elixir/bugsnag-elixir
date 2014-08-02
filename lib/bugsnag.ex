defmodule Bugsnag do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: "0.0.1",
    url: "https://github.com/jarednorman/bugsnag-elixir",
  }
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  use HTTPoison.Base

  # Public

  def crash(error) do
    post(@notify_url, payload(error), @request_headers)
  end

  # Private

  def payload(error) do
    { :ok, json } = %{}
    |> add_api_key
    |> add_notifier_info
    |> add_event(error)
    |> JSEX.encode
    json
  end

  defp add_api_key(payload) do
    { _, api_key } = :application.get_env(:bugsnag, :api_key)
    Map.put payload, :apiKey, api_key
  end

  defp add_notifier_info(payload)do
    Map.put payload, :notifier, @notifier_info
  end

  defp add_event(payload, error) do
    exception = Exception.normalize(:error, error)
    Map.put payload, :events, [ %{
      payloadVersion: "2",
      exceptions: [ %{
        errorClass: exception.__struct__,
        message: Exception.message(exception),
        stacktrace: format_stacktrace
      } ],
      severity: "error"
    } ]
  end

  defp format_stacktrace do
    System.stacktrace
    |> Enum.map fn
      ({ module, function, arity, [] }) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: "#{ module }.#{ function }/#{ arity }"
        }
      ({ module, function, arity, [ file: file, line: line_number ] }) ->
        %{
          file: file |> List.to_string,
          lineNumber: line_number,
          method: "#{ module }.#{ function }/#{ arity }"
        }
    end
  end
end
