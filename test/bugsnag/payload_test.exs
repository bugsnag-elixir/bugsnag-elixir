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
    %{exceptions: [ exception ]} = get_event(options)
    exception
  end

  test "it adds the context when given" do
    assert "Potato#cake" == get_event(context: "Potato#cake").context
  end


  test "it generates correct stacktraces" do
    {exception, stacktrace} = try do
      Enum.join(3, 'million')
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} = Payload.new(exception, stacktrace, [])
    assert [%{file: "lib/enum.ex", lineNumber: _, method: _},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: "Elixir.Bugsnag.PayloadTest.test it generates correct stacktraces/1"}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    assert [%{file: "unknown", lineNumber: 0, method: _},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: 9, method: "Elixir.Bugsnag.PayloadTest.get_problem/0"},
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
    assert [%{file: "unknown", lineNumber: 0, method: "Elixir.Fart.poo(:butts, 1, \"foo\\n\")"},
            %{file: "test/bugsnag/payload_test.exs", lineNumber: _, method: _} | _] = stacktrace
  end

  test "it reports the error class" do
    assert UndefinedFunctionError == get_exception.errorClass
  end

  test "it reports the error message" do
    assert "undefined function: Harbour.cats/1 (module Harbour is not available)" == get_exception.message
  end

  test "it reports the error severity" do
    assert "error" == get_event.severity
  end

  test "it reports the payload version" do
    assert "2" == get_event.payloadVersion
  end

  test "it sets the API key" do
    assert Application.get_env(:bugsnag, :api_key) == get_payload.apiKey
  end

  test "it reports the notifier" do
    assert %{name: "Bugsnag Elixir",
             url: "https://github.com/jarednorman/bugsnag-elixir",
             version: _} = get_payload.notifier
  end

  test "it adds metadata" do
    assert %{"app" => "my-app"} == get_event(metadata: %{"app" => "my-app"}).metaData
  end
end
