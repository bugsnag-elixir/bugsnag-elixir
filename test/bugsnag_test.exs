
defmodule BugsnagTest do
  use ExUnit.Case

  # Warning: because we report line numbers of the errors, these test are
  # extremely fragile and will later be replaced with better tests on the
  # payload before it is encoded as JSON.

  test "it converts errors to json" do
    try do
      Enum.join(3, "")
    catch
      _kind, error ->
        assert Bugsnag.payload(error) ==
          "{\"apiKey\":null,\"events\":[{\"exceptions\":[{\"errorClass\":\"Elixir.Protocol.UndefinedError\",\"message\":\"protocol Enumerable not implemented for 3\",\"stacktrace\":[{\"file\":\"lib/enum.ex\",\"lineNumber\":1,\"method\":\"Elixir.Enumerable.impl_for!/1\"},{\"file\":\"lib/enum.ex\",\"lineNumber\":112,\"method\":\"Elixir.Enumerable.reduce/3\"},{\"file\":\"lib/enum.ex\",\"lineNumber\":1250,\"method\":\"Elixir.Enum.reduce/3\"},{\"file\":\"lib/enum.ex\",\"lineNumber\":934,\"method\":\"Elixir.Enum.join/2\"},{\"file\":\"test/bugsnag_test.exs\",\"lineNumber\":11,\"method\":\"Elixir.BugsnagTest.test it converts errors to json/1\"},{\"file\":\"lib/ex_unit/runner.ex\",\"lineNumber\":233,\"method\":\"Elixir.ExUnit.Runner.exec_test/2\"},{\"file\":\"timer.erl\",\"lineNumber\":165,\"method\":\"timer.tc/1\"},{\"file\":\"lib/ex_unit/runner.ex\",\"lineNumber\":199,\"method\":\"Elixir.ExUnit.Runner.-spawn_test/3-fun-1-/3\"}]}],\"payloadVersion\":\"2\",\"severity\":\"error\"}],\"notifier\":{\"name\":\"Bugsnag Elixir\",\"url\":\"https://github.com/jarednorman/bugsnag-elixir\",\"version\":\"0.0.1\"}}"
    end
  end

  test "it converts errors to json when the error location isn't available" do
    try do
      "Potato" = "Polkey"
    catch
      _kind, error ->
        assert Bugsnag.payload(error) ==
          "{\"apiKey\":null,\"events\":[{\"exceptions\":[{\"errorClass\":\"Elixir.MatchError\",\"message\":\"no match of right hand side value: \\\"Polkey\\\"\",\"stacktrace\":[{\"file\":\"test/bugsnag_test.exs\",\"lineNumber\":21,\"method\":\"Elixir.BugsnagTest.test it converts errors to json when the error location isn't available/1\"},{\"file\":\"lib/ex_unit/runner.ex\",\"lineNumber\":233,\"method\":\"Elixir.ExUnit.Runner.exec_test/2\"},{\"file\":\"timer.erl\",\"lineNumber\":165,\"method\":\"timer.tc/1\"},{\"file\":\"lib/ex_unit/runner.ex\",\"lineNumber\":199,\"method\":\"Elixir.ExUnit.Runner.-spawn_test/3-fun-1-/3\"}]}],\"payloadVersion\":\"2\",\"severity\":\"error\"}],\"notifier\":{\"name\":\"Bugsnag Elixir\",\"url\":\"https://github.com/jarednorman/bugsnag-elixir\",\"version\":\"0.0.1\"}}"
    end
  end
end
