defmodule BugsnagTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  test "it doesn't raise errors if you report garbage" do
    capture_log fn ->
      Bugsnag.report(Enum, %{ignore: :this_error_in_test})
    end
  end

  test "it returns proper results if you use sync_report" do
    assert :ok = Bugsnag.sync_report(RuntimeError.exception("some_error"))
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

  test "it properly sets config" do
    assert Application.get_env(:bugsnag, :release_stage) == "test"
    assert Application.get_env(:bugsnag, :api_key) == "FAKEKEY"
    assert Application.get_env(:bugsnag, :use_logger) == true

  end

  test "it should not explode with logger unset" do
    Application.put_env(:bugsnag, :use_logger, nil)
    on_exit fn -> Application.put_env(:bugsnag, :use_logger, true) end

    Bugsnag.start(:temporary, %{})
    assert Application.get_env(:bugsnag, :use_logger) == nil
  end
end
