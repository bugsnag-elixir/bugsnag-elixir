defmodule BugsnagTest do
  use ExUnit.Case

  def get_problem do
    try do
      # If the following line is not on line 8 then tests will start failing.
      # You've been warned!
      Harbour.cats(3)
    rescue
      exception -> {exception, System.stacktrace}
    end
  end

  def get_payload do
    {exception, stacktrace} = get_problem
    Bugsnag.payload(exception, stacktrace)
  end

  def get_event do
    %{events: [event]} = get_payload
    event
  end

  def get_exception do
    %{exceptions: [ exception ]} = get_event
    exception
  end

  # I don't normally test that things don't happen, but in this case I would
  # consider it mission-critical that the error reporter not raise errors.
  test "it doesn't raise errors if you report garbage" do
    Bugsnag.report(Enum, %{canadian: "beer"})
  end

  test "it generates correct stacktraces" do
    {exception, stacktrace} = try do
      Enum.join(3, 'million')
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} = Bugsnag.payload(exception, stacktrace)
    assert [%{file: "lib/enum.ex", lineNumber: _, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: "Elixir.BugsnagTest.test it generates correct stacktraces/1"}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    assert [%{file: "unknown", lineNumber: 0, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: 8, method: "Elixir.BugsnagTest.get_problem/0"},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: _} | _] = get_exception.stacktrace
  end

  test "it reports the error class" do
    assert UndefinedFunctionError == get_exception.errorClass
  end

  test "it reports the error message" do
    assert "undefined function: Harbour.cats/1" == get_exception.message
  end

  test "it reports the error severity" do
    assert "error" == get_event.severity
  end

  test "it reports the payload version" do
    assert "2" == get_event.payloadVersion
  end

  test "it sets the API key" do
    assert "LOLIGOTCHA" = get_payload.apiKey
  end

  test "it reports the notifier" do
    assert %{name: "Bugsnag Elixir",
             url: "https://github.com/jarednorman/bugsnag-elixir",
             version: _} = get_payload.notifier
  end
end
