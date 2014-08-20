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

  def get_exception(payload) do
    %{events: [%{exceptions: [ exception ]}]} = payload
    exception
  end

  test "it generates correct stacktraces" do
    {exception, stacktrace} = try do
      Enum.join(3, 'million')
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{stacktrace: stacktrace} = Bugsnag.payload(exception, stacktrace) |> get_exception
    assert [%{file: "lib/enum.ex", lineNumber: _, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: "Elixir.BugsnagTest.test it generates correct stacktraces/1"}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    {exception, stacktrace} = get_problem
    %{stacktrace: stacktrace} = Bugsnag.payload(exception, stacktrace) |> get_exception
    assert [%{file: "unknown", lineNumber: 0, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: 8, method: "Elixir.BugsnagTest.get_problem/0"},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: _} | _] = stacktrace
  end

  test "it reports the error class" do
    {exception, stacktrace} = get_problem
    %{errorClass: error_class} = Bugsnag.payload(exception, stacktrace) |> get_exception
    assert UndefinedFunctionError == error_class
  end

  test "it reports the error message" do
    {exception, stacktrace} = get_problem
    %{message: message} = Bugsnag.payload(exception, stacktrace) |> get_exception
    assert "undefined function: Harbour.cats/1" == message
  end

  test "it reports the error severity" do
    {exception, stacktrace} = get_problem
    %{events: [event]} = Bugsnag.payload(exception, stacktrace)
    assert "error" == event.severity
  end

  test "it reports the payload version" do
    {exception, stacktrace} = get_problem
    %{events: [event]} = Bugsnag.payload(exception, stacktrace)
    assert "2" == event.payloadVersion
  end

  test "it sets the API key" do
    {exception, stacktrace} = get_problem
    %{apiKey: api_key} = Bugsnag.payload(exception, stacktrace)
    assert "LOLIGOTCHA" = api_key
  end

  test "it reports the notifier" do
    {exception, stacktrace} = get_problem
    %{notifier: notifier} = Bugsnag.payload(exception, stacktrace)
    assert %{name: "Bugsnag Elixir",
             url: "https://github.com/jarednorman/bugsnag-elixir",
             version: _} = notifier
  end
end
