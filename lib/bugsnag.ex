defmodule Bugsnag do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: Bugsnag.Mixfile.project[:version],
    url: Bugsnag.Mixfile.project[:package][:links][:github],
  }
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  use HTTPoison.Base

  # Public

  # Currently we only support reporting exceptions.
  def report(exception, stacktrace, options \\ []) do
    spawn fn ->
      post(@notify_url,
           payload(exception, stacktrace, options) |> to_json,
           @request_headers)
    end
  end

  # Private

  def payload(exception, stacktrace, options) do
    %{}
    |> add_api_key
    |> add_notifier_info
    |> add_event exception, stacktrace, Keyword.get(options, :context)
  end

  defp to_json(payload) do
    payload
    |> JSEX.encode
    |> elem(1)
  end

  defp add_api_key(payload) do
    { _, api_key } = :application.get_env(:bugsnag, :api_key)
    Map.put payload, :apiKey, api_key
  end

  defp add_notifier_info(payload)do
    Map.put payload, :notifier, @notifier_info
  end

  defp add_event(payload, exception, stacktrace, context) do
    event = %{}
    |> add_payload_version
    |> add_exception(exception, stacktrace)
    |> add_severity
    |> add_context(context)
    Map.put payload, :events, [event]
  end

  defp add_exception(event, exception, stacktrace) do
    Map.put event, :exceptions, [ %{
      errorClass: exception.__struct__,
      message: Exception.message(exception),
      stacktrace: format_stacktrace(stacktrace)
    } ]
  end

  defp add_payload_version(event), do: Map.put(event, :payloadVersion, "2")
  defp add_severity(event), do: Map.put(event, :severity, "error")

  defp add_context(event, nil), do: event
  defp add_context(event, context), do: Map.put(event, :context, context)

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) when is_list(args) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: "#{ module }.#{ function }(#{ args |> Enum.map(&(inspect(&1))) |> Enum.join(", ") })"
        }
      ({ module, function, arity, [] }) when is_number(arity) ->
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
