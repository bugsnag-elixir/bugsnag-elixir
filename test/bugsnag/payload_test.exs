defmodule Bugsnag.PayloadTest do
  use ExUnit.Case
  alias Bugsnag.Payload

  def get_problem do
    try do
      # If the following line is not on line 9 then tests will start failing.
      # You've been warned!
      raise "an error occurred"
    rescue
      exception -> [exception, __STACKTRACE__]
    end
  end

  def get_payload(options \\ []) do
    apply(Payload, :new, List.insert_at(get_problem(), -1, options))
  end

  def get_event(options \\ []) do
    %{events: [event]} = get_payload(options)
    event
  end

  def get_exception(options \\ []) do
    %{exceptions: [exception]} = get_event(options)
    exception
  end

  test "it adds the context when given" do
    assert "Potato#cake" == get_event(context: "Potato#cake").context
  end

  test "it adds metadata when given" do
    metadata = %{some_data: %{some_more: "some string"}}
    assert metadata == get_event(metadata: metadata).metaData
  end

  test "metaData is nil when not given" do
    refute Map.has_key?(get_event(), :metaData)
  end

  test "it adds error_class when given" do
    error_class = CustomError
    assert error_class == get_exception(error_class: error_class).errorClass
  end

  test "errorClass defaults to the exception struct module" do
    [exception, _] = get_problem()
    assert exception.__struct__ == get_exception().errorClass
  end

  test "it generates correct stacktraces" do
    {exception, stacktrace} =
      try do
        Enum.join(3, 'million')
      rescue
        exception -> {exception, __STACKTRACE__}
      end

    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} =
      Payload.new(exception, stacktrace, [])

    [
      %{file: "lib/enum.ex", lineNumber: _, method: _},
      %{
        file: "test/bugsnag/payload_test.exs",
        lineNumber: _,
        method: ~s(Bugsnag.PayloadTest."test it generates correct stacktraces"/1)
      }
      | _
    ] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    [
      %{
        file: "test/bugsnag/payload_test.exs",
        lineNumber: 9,
        method: "Bugsnag.PayloadTest.get_problem/0"
      },
      %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: _} | _
    ] = get_exception().stacktrace
  end

  # NOTE: Regression test
  test "it generates correct stacktraces when the method arguments are in place of arity" do
    {exception, stacktrace} =
      try do
        Module.concat(Elixir, "Movies").watch(:thor, 3, "ragnarok\n")
      rescue
        exception -> {exception, __STACKTRACE__}
      end

    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} =
      Payload.new(exception, stacktrace, [])

    [
      %{file: _, lineNumber: _, method: "Movies.watch(:thor, 3, \"ragnarok\\n\")"},
      %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: _, code: _} | _
    ] = stacktrace
  end

  # NOTE: this prevents all UndefinedFunctionError occurrences to be grouped into a single error
  test "location for an undefined function is same as caller" do
    {exception, stacktrace} =
      try do
        Module.concat(Elixir, "Bugsnag.Payload").non_existent_func()
      rescue
        exception -> {exception, __STACKTRACE__}
      end

    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} =
      Payload.new(exception, stacktrace, [])

    [
      %{file: file1, lineNumber: ln1, method: "Bugsnag.Payload.non_existent_func()"},
      %{file: file2, lineNumber: ln2, method: _, code: _} | _
    ] = stacktrace

    assert file1 == file2
    assert ln1 == ln2
  end

  test "it generates correct stacktraces for :erl_stdlib_errors" do
    {exception, stacktrace} =
      try do
        :ets.select(:does_not_exist, [{{:"$1", :_}, [], [:"$1"]}])
      rescue
        exception -> {exception, __STACKTRACE__}
      end

    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} =
      Payload.new(exception, stacktrace, [])

    [
      %{
        file: "test/bugsnag/payload_test.exs",
        lineNumber: _,
        inProject: false,
        method: ":ets.select(:does_not_exist, [{{:\"$1\", :_}, [], [:\"$1\"]}])"
      },
      %{
        file: "test/bugsnag/payload_test.exs",
        lineNumber: _,
        method:
          ~s(Bugsnag.PayloadTest."test it generates correct stacktraces for :erl_stdlib_errors"/1)
      }
      | _
    ] = stacktrace
  end

  test "reports stack frames as not being in-project by default" do
    [
      %{file: "test/bugsnag/payload_test.exs", inProject: false} | _
    ] = get_exception().stacktrace
  end

  test "allows in-project classification based on substring match of the filename" do
    in_project = "bugsnag/payload_test"

    [
      %{file: "test/bugsnag/payload_test.exs", inProject: true} | _
    ] = get_exception(in_project: in_project).stacktrace
  end

  test "allows in-project classification based on regex match of the filename" do
    in_project = ~r(^test.*bugsnag)

    [
      %{file: "test/bugsnag/payload_test.exs", inProject: true} | _
    ] = get_exception(in_project: in_project).stacktrace
  end

  test "allows in-project classification by calling an anonymous function per stack frame" do
    in_project = fn {_mod, fun, _args, _file} -> fun == :get_problem end

    [
      %{method: "Bugsnag.PayloadTest.get_problem/0", inProject: true},
      %{method: "Bugsnag.PayloadTest" <> _, inProject: false} | _
    ] = get_exception(in_project: in_project).stacktrace
  end

  test "allows in-project classification by calling a module function per stack frame" do
    defmodule MyApp do
      def in_project?({_mod, fun, _args, _file}, extra_arg), do: fun == extra_arg
    end

    in_project = {MyApp, :in_project?, [:get_problem]}

    [
      %{method: "Bugsnag.PayloadTest.get_problem/0", inProject: true},
      %{method: "Bugsnag.PayloadTest" <> _, inProject: false} | _
    ] = get_exception(in_project: in_project).stacktrace
  end

  test "it reports the error class" do
    assert RuntimeError == get_exception().errorClass
  end

  test "it reports the error message" do
    assert get_exception().message =~ "an error occurred"
  end

  test "it reports the error severity" do
    assert "error" == get_event().severity
    assert "info" == get_event(severity: "info").severity
    assert "warning" == get_event(severity: "warning").severity
    assert "error" == get_event(severity: "").severity
    assert "error" == get_event(severity: :error).severity
    assert "info" == get_event(severity: :info).severity
    assert "warning" == get_event(severity: :warning).severity
    assert "error" == get_event(severity: :another).severity
  end

  test "it reports the release stage" do
    assert "production" == get_event().app.releaseStage
    assert "staging" == get_event(release_stage: "staging").app.releaseStage
    assert "qa" == get_event(release_stage: "qa").app.releaseStage
    assert "" == get_event(release_stage: "").app.releaseStage
  end

  test "it reports the notify release stages" do
    assert ["production"] == get_event().notifyReleaseStages
    assert ["staging"] == get_event(notify_release_stages: ["staging"]).notifyReleaseStages
    assert ["qa"] == get_event(notify_release_stages: ["qa"]).notifyReleaseStages
    assert [""] == get_event(notify_release_stages: [""]).notifyReleaseStages
  end

  test "it reports the payload version" do
    assert "2" == get_event().payloadVersion
  end

  test "it sets the API key if configured" do
    assert "FAKEKEY" == get_payload().api_key
  end

  test "it sets the API key from options, even when configured" do
    assert "anotherkey" == get_payload(api_key: "anotherkey").api_key
  end

  test "is sets the device info if given" do
    evt = get_event(os_version: "some-version 1.0", hostname: "some-host")
    assert "some-version 1.0" == evt.device.osVersion
    assert "some-host" == evt.device.hostname
  end

  test "it reports the hostname in the application's config if specified" do
    assert "unknown" == get_event().device.hostname
    assert "some-host" == get_event(hostname: "some-host").device.hostname
  end

  test "it reports the app type" do
    assert "elixir" == get_event().app.type
    assert "phoenix" == get_event(app_type: "phoenix").app.type
  end

  test "app version isn't set by default" do
    refute Map.has_key?(get_event().app, :version)
  end

  test "it reports the app version" do
    assert "1.2.3" == get_event(app_version: "1.2.3").app.version
  end

  test "it reports the notifier" do
    %{
      name: "Bugsnag Elixir",
      url: "https://github.com/bugsnag-elixir/bugsnag-elixir",
      version: _
    } = get_payload().notifier
  end

  for json_library <- [nil, Jason, Poison] do
    desc = if json_library, do: inspect(json_library), else: "default JSON library"

    test "it encodes `apiKey` using #{desc}" do
      json_library = unquote(json_library)

      if json_library do
        Application.put_env(:bugsnag, :json_library, json_library)
      else
        Application.delete_env(:bugsnag, :json_library)
      end

      decoded_payload =
        get_payload()
        |> Payload.encode()
        |> Jason.decode!()

      assert decoded_payload["apiKey"] == "FAKEKEY"
    end
  end
end
