defmodule BugsnagTest do
  use ExUnit.Case
  # I don't normally test that things don't happen, but in this case I would
  # consider it mission-critical that the error reporter not raise errors.
  test "it doesn't raise errors if you report garbage" do
    Bugsnag.report(Enum, %{canadian: "beer"})
  end
end
