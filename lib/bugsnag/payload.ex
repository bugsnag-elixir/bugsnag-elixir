defmodule Bugsnag.Payload do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: Bugsnag.Mixfile.project[:version],
    url: Bugsnag.Mixfile.project[:package][:links][:github],
  }

  defstruct api_key: nil, notifier: @notifier_info, events: nil

  def new(exception, stacktrace, options) do
    %__MODULE__{}
    |> add_api_key
    |> add_event(exception,
                 stacktrace,
                 Keyword.get(options, :context),
                 Keyword.get(options, :severity),
                 Keyword.get(options, :release_stage),
                 Keyword.get(options, :metadata))
  end

  defp add_api_key(payload) do
    payload
    |> Map.put(:apiKey, Application.get_env(:bugsnag, :api_key))
  end

  defp add_event(payload, exception, stacktrace, context, severity, release_stage, metadata) do
    event = %{}
    |> add_payload_version
    |> add_exception(exception, stacktrace)
    |> add_severity(severity)
    |> add_context(context)
    |> add_release_stage(release_stage)
    |> add_metadata(metadata)
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

  defp add_release_stage(event, release_stage) when is_binary(release_stage), do: Map.put(event, :app, %{releaseStage: release_stage})
  defp add_release_stage(event, _), do: Map.put(event, :app, %{releaseStage: "production"})

  defp add_context(event, nil), do: event
  defp add_context(event, context), do: Map.put(event, :context, context)

  defp add_metadata(event, nil), do: event
  defp add_metadata(event, metadata), do: Map.put(event, :metaData, metadata)

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
