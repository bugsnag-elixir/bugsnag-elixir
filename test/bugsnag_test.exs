defmodule BugsnagTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  test "it doesn't raise errors if you report garbage" do
    capture_log fn ->
      Bugsnag.report(Enum, %{ignore: :this_error_in_test})
    end
  end

  test "it returns proper results if you use sync_report" do
    Application.put_env(:bugsnag, :release_stage, "production")
    on_exit fn -> Application.delete_env(:bugsnag, :release_stage) end

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
    Bugsnag.start(:ok, :ok)
    assert Application.get_env(:bugsnag, :release_stage) == "production"
    assert Application.get_env(:bugsnag, :api_key) == "FAKEKEY"
    assert Application.get_env(:bugsnag, :use_logger) == true
    assert Application.get_env(:bugsnag, :notify_release_stages) == ["production"]
  end

  test "it should not explode with logger unset" do
    Application.put_env(:bugsnag, :use_logger, nil)
    on_exit fn -> Application.put_env(:bugsnag, :use_logger, true) end

    Bugsnag.start(:temporary, %{})
    assert Application.get_env(:bugsnag, :use_logger) == nil
  end

  test "does not notify bugsnag if you use sync_report and release_stage is not included in the notify_release_stages" do
    Application.put_env(:bugsnag, :release_stage, "development")
    on_exit fn -> Application.delete_env(:bugsnag, :release_stage) end

    refute Application.get_env(:bugsnag, :notify_release_stages) == ["development"]
    assert {:ok, :not_sent} = Bugsnag.sync_report(RuntimeError.exception("some_error"))
  end

  test "notifies bugsnag if you use sync_report and release_stage is included in the notify_release_stages" do
    Application.put_env(:bugsnag, :release_stage, "development")
    Application.put_env(:bugsnag, :notify_release_stages, ["development"])

    on_exit fn -> Application.delete_env(:bugsnag, :release_stage) end
    on_exit fn -> Application.delete_env(:bugsnag, :notify_release_stages) end

    assert :ok = Bugsnag.sync_report(RuntimeError.exception("some_error"))
  end
end
