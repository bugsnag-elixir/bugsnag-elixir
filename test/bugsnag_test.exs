defmodule BugsnagTest do
  use ExUnit.Case

  test "it doesn't raise errors if you report garbage" do
    Bugsnag.report(Enum, %{canadian: "beer"})
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
      "{\"bar\":\"baz\",\"foo\":3}"
  end
end
