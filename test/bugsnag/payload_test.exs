defmodule Bugsnag.PayloadTest do
  use ExUnit.Case
  alias Bugsnag.Payload

  def get_problem do
    try do
      # If the following line is not on line 9 then tests will start failing.
      # You've been warned!
      Harbour.cats(3)
    rescue
      exception -> [exception, System.stacktrace]
    end
  end

  def get_payload(options \\ []) do
    apply Payload, :new, List.insert_at(get_problem, -1, options)
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
    refute Map.has_key?(get_event, :metaData)
  end

  test "it generates correct stacktraces" do
    {exception, stacktrace} =
      try do
        Enum.join(3, 'million')
      rescue
        exception -> {exception, System.stacktrace}
      end

    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} = Payload.new(exception, stacktrace, [])
    assert [%{file: "lib/enum.ex", lineNumber: _, method: _},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: ~s(Bugsnag.PayloadTest."test it generates correct stacktraces"/1)}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    assert [%{file: "unknown", lineNumber: 0, method: _},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: 9, method: "Bugsnag.PayloadTest.get_problem/0"},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: _} | _] = get_exception.stacktrace
  end

  # NOTE: Regression test
  test "it generates correct stacktraces when the method arguments are in place of arity" do
    {exception, stacktrace} = try do
      Fart.poo(:butts, 1, "foo\n")
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} = Payload.new(exception, stacktrace, [])
    assert [%{file: "unknown", lineNumber: 0, method: "Fart.poo(:butts, 1, \"foo\\n\")"},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: _, code: _} | _] = stacktrace
  end

  test "it reports the error class" do
    assert UndefinedFunctionError == get_exception.errorClass
  end

  test "it reports the error message" do
    assert get_exception.message =~ "(module Harbour is not available)"
  end

  test "it reports the error severity" do
    assert "error" == get_event.severity
    assert "info" == get_event(severity: "info").severity
    assert "warning" == get_event(severity: "warning").severity
    assert "error" == get_event(severity: "").severity
  end

  test "it reports the release stage" do
    assert "test"    == get_event.app.releaseStage
    assert "staging" == get_event(release_stage: "staging").app.releaseStage
    assert "qa"      == get_event(release_stage: "qa").app.releaseStage
    assert ""        == get_event(release_stage: "").app.releaseStage
  end

  test "it reports the payload version" do
    assert "2" == get_event.payloadVersion
  end

  test "it sets the API key if configured" do
    assert "FAKEKEY" == get_payload.apiKey
  end

  test "it sets the API key from options, even when configured" do
    assert "anotherkey" == get_payload(api_key: "anotherkey").apiKey
  end

  test "is sets the device info if given" do
    evt = get_event(os_version: "some-version 1.0", hostname: "some-host")
    assert "some-version 1.0" == evt.device.osVersion
    assert "some-host"        == evt.device.hostname
  end

  test "it reports the notifier" do
    assert %{name: "Bugsnag Elixir",
             url: "https://github.com/jarednorman/bugsnag-elixir",
             version: _} = get_payload.notifier
  end
end
