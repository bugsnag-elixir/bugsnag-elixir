defmodule Bugsnag.Payload do
  require Logger

  @notifier_info %{
    name: "Bugsnag Elixir",
    version: Bugsnag.Mixfile.project()[:version],
    url: Bugsnag.Mixfile.project()[:package][:links][:GitHub]
  }

  defstruct api_key: nil, notifier: @notifier_info, events: nil

  def new(exception, stacktrace, options) when is_map(options) do
    new(exception, stacktrace, Map.to_list(options))
  end

  def new(exception, stacktrace, options) do
    __MODULE__
    |> struct(api_key: fetch_option(options, :api_key))
    |> add_event(exception, stacktrace, options)
  end

  def encode(%__MODULE__{api_key: api_key, notifier: notifier, events: events}) do
    json_library().encode!(%{apiKey: api_key, notifier: notifier, events: events})
  end

  defp json_library, do: Application.get_env(:bugsnag, :json_library, Jason)

  defp fetch_option(options, key, default \\ nil) do
    Keyword.get(options, key, Application.get_env(:bugsnag, key, default))
  end

  defp add_event(payload, exception, stacktrace, options) do
    error = Exception.normalize(:error, exception)

    event =
      Map.new()
      |> add_payload_version
      |> add_exception(error, stacktrace, options)
      |> add_severity(Keyword.get(options, :severity))
      |> add_context(Keyword.get(options, :context))
      |> add_user(Keyword.get(options, :user))
      |> add_device(
        Keyword.get(options, :os_version),
        fetch_option(options, :hostname, "unknown")
      )
      |> add_metadata(Keyword.get(options, :metadata))
      |> add_release_stage(fetch_option(options, :release_stage, "production"))
      |> add_notify_release_stages(fetch_option(options, :notify_release_stages, ["production"]))
      |> add_app_type(fetch_option(options, :app_type))
      |> add_app_version(fetch_option(options, :app_version))

    Map.put(payload, :events, [event])
  end

  defp add_exception(event, exception, stacktrace, options) do
    Map.put(event, :exceptions, [
      %{
        errorClass: Keyword.get(options, :error_class, exception.__struct__),
        message: sanitize(Exception.message(exception)),
        stacktrace: format_stacktrace(stacktrace, options)
      }
    ])
  end

  defp add_payload_version(event), do: Map.put(event, :payloadVersion, "2")

  defp add_severity(event, severity) when severity in ~w(error warning info),
    do: Map.put(event, :severity, severity)

  defp add_severity(event, severity) when severity in ~w(error warning info)a,
    do: Map.put(event, :severity, "#{severity}")

  defp add_severity(event, _), do: Map.put(event, :severity, "error")

  defp add_release_stage(event, release_stage),
    do: Map.put(event, :app, %{releaseStage: release_stage})

  defp add_notify_release_stages(event, notify_release_stages),
    do: Map.put(event, :notifyReleaseStages, notify_release_stages)

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
      do: event,
      else: Map.put(event, :device, device)
  end

  defp add_app_type(event, type) do
    event
    |> Map.put_new(:app, %{})
    |> put_in([:app, :type], type)
  end

  defp add_app_version(event, nil), do: event

  defp add_app_version(event, version) do
    event
    |> Map.put_new(:app, %{})
    |> put_in([:app, :version], version)
  end

  defp add_metadata(event, nil), do: event
  defp add_metadata(event, metadata), do: Map.put(event, :metaData, metadata)

  defp format_stacktrace(stacktrace, options) do
    in_project_fn = get_in_project_fn(options)

    stacktrace
    |> Enum.reverse()
    |> Enum.reduce([], fn current_frame, acc ->
      {mod, function, arity_or_args, location} = current_frame
      last_frame = List.first(acc) || %{file: "unknown", lineNumber: 0, inProject: false}
      file = Keyword.get(location, :file)
      line = Keyword.get(location, :line)

      in_project =
        if file,
          do: in_project_fn.({mod, function, arity_or_args, to_string(file)}),
          else: last_frame.inProject

      frame =
        %{
          file: to_string(file || last_frame.file),
          lineNumber: line || last_frame.lineNumber,
          inProject: in_project,
          method: sanitize(Exception.format_mfa(mod, function, arity_or_args))
        }
        |> may_put_code(%{file: file, line: line})

      [frame | acc]
    end)
  end

  defp may_put_code(frame, %{line: nil}), do: frame

  defp may_put_code(frame, %{file: file, line: line}) do
    Map.put_new(frame, :code, get_file_contents(file, line))
  end

  defp get_in_project_fn(options) do
    case fetch_option(options, :in_project, nil) do
      func when is_function(func) ->
        func

      {mod, fun, args} ->
        fn stack_frame -> apply(mod, fun, [stack_frame | args]) end

      %Regex{} = re ->
        fn {_m, _f, _a, file} -> Regex.match?(re, file) end

      str when is_binary(str) ->
        fn {_m, _f, _a, file} -> String.contains?(file, str) end

      _other ->
        fn _ -> false end
    end
  end

  defp get_file_contents(file, line_number) do
    file = File.cwd!() |> Path.join(file)

    if File.exists?(file) do
      file
      |> File.stream!()
      |> Stream.with_index()
      |> Stream.map(fn {line, index} -> {to_string(index + 1), line} end)
      |> Enum.slice(if(line_number - 4 > 0, do: line_number - 4, else: 0), 7)
      |> Enum.into(%{})
    end
  end

  defp sanitize(value) do
    sanitizer = Application.get_env(:bugsnag, :sanitizer)

    if sanitizer do
      {module, function} = sanitizer
      apply(module, function, [value])
    else
      value
    end
  rescue
    _ ->
      Logger.warn("Bugsnag Sanitizer failed to sanitize a value")

      "[CENSORED DUE TO SANITIZER EXCEPTION]"
  end
end
