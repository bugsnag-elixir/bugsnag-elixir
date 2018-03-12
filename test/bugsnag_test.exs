defmodule BugsnagTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  test "it doesn't raise errors if you report garbage" do
    capture_log fn ->
      Bugsnag.report(Enum, %{ignore: :this_error_in_test})
    end
  end

  test "it returns proper results if you use sync_report" do
    old_release_stage = Application.get_env(:bugsnag, :release_stage)
    Application.put_env(:bugsnag, :release_stage, "production")
    on_exit fn -> Application.put_env(:bugsnag, :release_stage, old_release_stage) end

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

  test "it puts application env values on startup" do
    assert Application.get_env(:bugsnag, :release_stage) == "production"
    assert Application.get_env(:bugsnag, :api_key) == "FAKEKEY"
    assert Application.get_env(:bugsnag, :use_logger) == true
    assert Application.get_env(:bugsnag, :notify_release_stages) == ["production"]
  end

  test "it warns if no api_key is configured" do
    {:ok, old_key} = Application.fetch_env(:bugsnag, :api_key)
    Application.delete_env(:bugsnag, :api_key)
    on_exit fn -> Application.put_env(:bugsnag, :api_key, old_key) end

    assert capture_log(fn -> Bugsnag.start(:temporary, %{}) end) =~ "api_key is not configured"
  end

  test "it doesn't warn about api_key if the current release stage is not a notifying one" do
    {:ok, old_stage} = Application.fetch_env(:bugsnag, :release_stage)
    Application.put_env(:bugsnag, :release_stage, "development")
    on_exit fn -> Application.put_env(:bugsnag, :release_stage, old_stage) end

    assert capture_log(fn -> Bugsnag.start(:temporary, %{}) end) == ""
  end

  test "it should not explode with logger unset" do
    Application.put_env(:bugsnag, :use_logger, nil)
    on_exit fn -> Application.put_env(:bugsnag, :use_logger, true) end

    Bugsnag.start(:temporary, %{})
    assert Application.get_env(:bugsnag, :use_logger) == nil
  end

  test "warns and returns an error when sending a report with no API key configured" do
    {:ok, old_key} = Application.fetch_env(:bugsnag, :api_key)
    Application.delete_env(:bugsnag, :api_key)
    on_exit fn -> Application.put_env(:bugsnag, :api_key, old_key) end

    log = capture_log fn ->
      assert {:error, %{reason: "API key is not configured"}} == Bugsnag.sync_report("error!")
    end
    assert log =~ "api_key is not configured"
  end

  test "does not notify bugsnag if you use sync_report and release_stage is not included in the notify_release_stages" do
    old_release_stage = Application.get_env(:bugsnag, :release_stage)
    Application.put_env(:bugsnag, :release_stage, "development")
    on_exit fn -> Application.put_env(:bugsnag, :release_stage, old_release_stage) end

    refute Enum.member?(Application.get_env(:bugsnag, :notify_release_stages), "development")
    assert {:ok, :not_sent} = Bugsnag.sync_report(RuntimeError.exception("some_error"))
  end

  test "notifies bugsnag if you use sync_report and release_stage is included in the notify_release_stages" do
    old_release_stage = Application.get_env(:bugsnag, :release_stage)
    old_notify_stages = Application.get_env(:bugsnag, :notify_release_stages)

    Application.put_env(:bugsnag, :release_stage, "development")
    Application.put_env(:bugsnag, :notify_release_stages, ["development"])

    on_exit fn -> Application.put_env(:bugsnag, :release_stage, old_release_stage) end
    on_exit fn -> Application.put_env(:bugsnag, :notify_release_stages, old_notify_stages) end

    assert :ok = Bugsnag.sync_report(RuntimeError.exception("some_error"))
  end
end
