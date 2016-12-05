defmodule Bugsnag.Payload do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: Bugsnag.Mixfile.project[:version],
    url: Bugsnag.Mixfile.project[:package][:links][:github],
  }

  defstruct api_key: nil, notifier: @notifier_info, events: nil

  def new(exception, stacktrace, options) when is_map(options) do
    new(exception, stacktrace, Map.to_list(options))
  end

  def new(exception, stacktrace, options) do
    %__MODULE__{}
    |> Map.put(:apiKey, fetch_option(options, :api_key))
    |> add_event(exception, stacktrace, options)
  end

  defp fetch_option(options, key, default \\ "development") do
    Keyword.get options, key, Application.get_env(:bugsnag, key, default)
  end

  defp add_event(payload, exception, stacktrace, options) do
    error = Exception.normalize(:error, exception)

    event =
      Map.new
      |> add_payload_version
      |> add_exception(error, stacktrace)
      |> add_severity(Keyword.get(options, :severity))
      |> add_context(Keyword.get(options, :context))
      |> add_user(Keyword.get(options, :user))
      |> add_device(Keyword.get(options, :os_version), Keyword.get(options, :hostname))
      |> add_metadata(Keyword.get(options, :metadata))
      |> add_release_stage(fetch_option(options, :release_stage, "production"))

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

  defp add_release_stage(event, release_stage), do: Map.put(event, :app, %{releaseStage: release_stage})

  defp add_context(event, nil), do: event
  defp add_context(event, context), do: Map.put(event, :context, context)

  defp add_user(event, nil), do: event
  defp add_user(event, user), do: Map.put(event, :user, user)

  defp add_device(event, os_version, hostname) do
    device =
      %{}
      |> Map.merge(if os_version, do: %{osVersion: os_version}, else: %{})
      |> Map.merge(if hostname, do: %{hostname: hostname}, else: %{})

    if Enum.empty?(device),
    do:   event,
    else: Map.put(event, :device, device)
  end

  defp add_metadata(event, nil), do: event
  defp add_metadata(event, metadata), do: Map.put(event, :metaData, metadata)

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: Exception.format_mfa(module, function, args)
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        file = to_string file
        %{
          file: file,
          lineNumber: line_number,
          inProject: Regex.match?(~r/^(lib|web)/, file),
          method: Exception.format_mfa(module, function, args),
          code: get_file_contents(file, line_number)
        }
    end
  end

  defp get_file_contents(file, line_number) do
    file = File.cwd! |> Path.join(file)

    if File.exists?(file) do
      file
      |> File.stream!
      |> Stream.with_index
      |> Stream.map(fn({line, index}) -> {to_string(index + 1), line} end)
      |> Enum.slice(if(line_number - 4 > 0, do: line_number - 4, else: 0), 7)
      |> Enum.into(%{})
    end
  end
end
