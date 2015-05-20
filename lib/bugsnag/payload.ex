defmodule Bugsnag.Payload do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: Bugsnag.Mixfile.project[:version],
    url: Bugsnag.Mixfile.project[:package][:links][:github],
  }

  defstruct apiKey: nil, notifier: @notifier_info, events: nil

  def new(exception, stacktrace, options) do
    %__MODULE__{}
    |> add_api_key
    |> add_event(exception,
                 stacktrace,
                 Keyword.get(options, :context),
                 Keyword.get(options, :severity)
                 )
  end

  defp add_api_key(payload) do
    payload
    |> Map.put :apiKey, Application.get_env(:bugsnag, :api_key)
  end

  defp add_event(payload, exception, stacktrace, context, severity) do
    event = %{}
    |> add_payload_version
    |> add_exception(exception, stacktrace)
    |> add_severity(severity)
    |> add_context(context)
    Map.put payload, :events, [event]
  end

  defp add_exception(event, exception, stacktrace) do
    Map.put event, :exceptions, [%{
      errorClass: exception.__struct__,
      message: Exception.message(exception),
      stacktrace: format_stacktrace(stacktrace)
    }]
  end

  defp add_payload_version(event), do: Map.put(event, :payloadVersion, "2")

  defp add_severity(event, severity) when severity in ~w(error warning info), do: Map.put(event, :severity, severity)
  defp add_severity(event, _), do: Map.put(event, :severity, "error")

  defp add_context(event, nil), do: event
  defp add_context(event, context), do: Map.put(event, :context, context)

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: "#{ module }.#{ function }#{ format_args(args) }"
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        %{
          file: file |> List.to_string,
          lineNumber: line_number,
          method: "#{ module }.#{ function }#{ format_args(args) }"
        }
    end
  end

  defp format_args(args) when is_integer(args) do
    "/#{args}"
  end
  defp format_args(args) when is_list(args) do
    "(#{args
        |> Enum.map(&(inspect(&1)))
        |> Enum.join(", ")})"
  end
end
