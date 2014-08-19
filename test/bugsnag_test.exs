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

  def get_stacktrace(payload) do
    %{events: [%{exceptions: [%{stacktrace: stacktrace}]}]} = payload
    stacktrace
  end

  test "it generates correct stacktraces" do
    {exception, stacktrace} = try do
      Enum.join(3, 'million')
    rescue
      exception -> {exception, System.stacktrace}
    end
    stacktrace = Bugsnag.payload(exception, stacktrace) |> get_stacktrace
    assert [%{file: "lib/enum.ex", lineNumber: _, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: "Elixir.BugsnagTest.test it generates correct stacktraces/1"}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    {exception, stacktrace} = get_problem
    stacktrace = Bugsnag.payload(exception, stacktrace) |> get_stacktrace
    assert [%{file: "unknown", lineNumber: 0, method: _},
            %{file: "test/bugsnag_test.exs", lineNumber: 8, method: "Elixir.BugsnagTest.get_problem/0"},
            %{file: "test/bugsnag_test.exs", lineNumber: _, method: _} | _] = stacktrace
  end
end
