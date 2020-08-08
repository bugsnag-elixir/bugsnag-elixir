defmodule Bugsnag.LoggerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias HTTPoison, as: HTTP

  setup_all do
    :error_logger.add_report_handler(Bugsnag.Logger)
    Application.put_env(:bugsnag, :release_stage, "test")
    Application.put_env(:bugsnag, :notify_release_stages, ["test"])

    on_exit(fn ->
      :error_logger.delete_report_handler(Bugsnag.Logger)
      Application.delete_env(:bugsnag, :release_stage)
      Application.delete_env(:bugsnag, :notify_release_stages)
    end)
  end

  test "logging a crash" do
    :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Response{} end)

    :proc_lib.spawn(fn ->
      raise RuntimeError, "Oops"
    end)

    :timer.sleep(250)

    assert :meck.called(HTTP, :post, [:_, :_, :_])
    :meck.unload(HTTP)
  end

  test "crashes do not cause recursive logging" do
    :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Error{reason: 500} end)

    log_msg =
      capture_log(fn ->
        error_report = [[error_info: {:error, %RuntimeError{message: "Oops"}, []}], []]
        :error_logger.error_report(error_report)
        :timer.sleep(250)
      end)

    assert log_msg =~ "[[error_info: {:error, %RuntimeError{message: \"Oops\"}, []}], []]"
    assert :meck.called(HTTP, :post, [:_, :_, :_])

    :meck.unload(HTTP)
  end

  test "log levels lower than :error_report are ignored" do
    message_types = [:info_msg, :info_report, :warning_msg, :error_msg]

    Enum.each(message_types, fn type ->
      log_msg =
        capture_log(fn ->
          :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Response{} end)
          apply(:error_logger, type, ["Ignore me"])
          :timer.sleep(250)
          refute :meck.called(HTTP, :post, [:_, :_, :_])
        end)

      assert log_msg =~ "Ignore me"
    end)

    :meck.unload(HTTP)
  end

  test "logging exceptions from special processes" do
    :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Response{} end)

    :proc_lib.spawn(fn ->
      Float.parse("12.345e308")
    end)

    :timer.sleep(250)

    assert :meck.called(HTTP, :post, [:_, :_, :_])
    :meck.unload(HTTP)
  end

  test "logging exceptions from Tasks" do
    :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Response{} end)

    log_msg =
      capture_log(fn ->
        Task.start(fn -> Float.parse("12.345e308") end)
        :timer.sleep(250)
      end)

    assert log_msg =~ "(ArgumentError) argument error"
    assert :meck.called(HTTP, :post, [:_, :_, :_])

    :meck.unload(HTTP)
  end

  test "logging exceptions from GenServers" do
    :meck.expect(HTTP, :post, fn _ex, _c, _s -> %HTTP.Response{} end)

    {:ok, pid} = ErrorServer.start()

    log_msg =
      capture_log(fn ->
        GenServer.cast(pid, :fail)
        :timer.sleep(250)
      end)

    # We assert either of these log messages because the log changed between elixir
    # versions. It feels like we shouldn't need to assert on the log message but...
    assert log_msg =~ "(stop) bad cast: :fail" || log_msg =~ "but no handle_cast"
    assert :meck.called(HTTP, :post, [:_, :_, :_])

    :meck.unload(HTTP)
  end

  test "warns if error report format is invalid" do
    event = {:error_report, :gl, {:pid, :type, [[error_info: :invalid]]}}

    log_msg =
      capture_log(fn ->
        Bugsnag.Logger.handle_event(event, :state)
      end)

    assert log_msg =~ "Unable to notify Bugsnag. ** (CaseClauseError)"
  end
end
