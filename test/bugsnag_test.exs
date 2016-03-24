defmodule BugsnagTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "it doesn't raise errors if you report garbage" do
    capture_io(:error_logger, fn ->
      Bugsnag.report(Enum, %{ignore: :this_error_in_test})
    end)
  end

  test "it handles real errors" do
    try do
      :foo = :bar
    rescue
      exception -> Bugsnag.report(exception)
    end
  end

  test "it can encode json" do
    assert Bugsnag.to_json(%{foo: 3, bar: "baz"}) ==
      "{\"foo\":3,\"bar\":\"baz\"}"
  end
end
