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
    |> add_event(exception, stacktrace, options)
  end

  defp add_api_key(payload) do
    payload
    |> Map.put :apiKey, Application.get_env(:bugsnag, :api_key)
  end

  defp add_event(payload, exception, stacktrace, options) do
    event =
      %{}
      |> add_payload_version
      |> add_exception(exception, stacktrace)
      |> add_severity(Keyword.get(options, :severity))
      |> add_context(Keyword.get(options, :context))
      |> add_user(Keyword.get(options, :user))
      |> add_metadata(Keyword.get(options, :metadata))
      |> add_env

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

  defp add_user(event, nil), do: event
  defp add_user(event, user), do: Map.put(event, :user, user)

  defp add_metadata(event, nil), do: event
  defp add_metadata(event, metadata), do: Map.put(event, :metaData, metadata)

  defp add_env(event), do: Map.put(event, :app, %{releaseStage: Mix.env})

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: Exception.format_mfa(module, function, args)
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        file = List.to_string file
        %{
          file: file,
          lineNumber: line_number,
          inProject: String.starts_with?(file, "web"),
          method: Exception.format_mfa(module, function, args),
          code: get_file_contents(file, line_number)
        }
    end
  end

  defp get_file_contents(file, line_number) do
    if String.starts_with? file, "web" do
      File.cwd!
      |> Path.join(file)
      |> File.stream!
      |> Stream.with_index
      |> Stream.map(fn({line, index}) -> {to_string(index + 1), line} end)
      |> Enum.slice(if(line_number - 4 > 0, do: line_number - 4, else: 0), 7)
      |> Enum.into(%{})
    end
  end
end
