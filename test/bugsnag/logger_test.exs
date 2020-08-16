defmodule Bugsnag.LoggerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  alias HTTPoison

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

  setup do
    :meck.new(HTTPoison, [:passthrough])

    on_exit(fn ->
      :meck.unload()
    end)

    :ok
  end

  test "logging a crash" do
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts -> %HTTPoison.Response{} end)

    :proc_lib.spawn(fn ->
      raise RuntimeError, "Oops"
    end)

    :timer.sleep(250)

    assert :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
  end

  test "crashes do not cause recursive logging" do
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts ->
      %HTTPoison.Error{reason: 500}
    end)

    log_msg =
      capture_log(fn ->
        error_report = [[error_info: {:error, %RuntimeError{message: "Oops"}, []}], []]
        :error_logger.error_report(error_report)
        :timer.sleep(250)
      end)

    assert log_msg =~ "[[error_info: {:error, %RuntimeError{message: \"Oops\"}, []}], []]"
    assert :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
  end

  test "log levels lower than :error_report are ignored" do
    message_types = [:info_msg, :info_report, :warning_msg, :error_msg]
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts -> %HTTPoison.Response{} end)

    Enum.each(message_types, fn type ->
      assert capture_log(fn ->
               apply(:error_logger, type, ["Ignore me"])
             end) =~ "Ignore me"
    end)

    :timer.sleep(250)
    refute :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
  end

  test "logging exceptions from special processes" do
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts -> %HTTPoison.Response{} end)

    :proc_lib.spawn(fn ->
      Float.parse("12.345e308")
    end)

    :timer.sleep(250)

    assert :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
  end

  test "logging exceptions from Tasks" do
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts -> %HTTPoison.Response{} end)

    log_msg =
      capture_log(fn ->
        Task.start(fn -> Float.parse("12.345e308") end)
        :timer.sleep(250)
      end)

    assert log_msg =~ "(ArgumentError) argument error"
    assert :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
  end

  test "logging exceptions from GenServers" do
    :meck.expect(HTTPoison, :post, fn _url, _body, _headers, _opts -> %HTTPoison.Response{} end)

    {:ok, pid} = ErrorServer.start()

    log_msg =
      capture_log(fn ->
        GenServer.cast(pid, :fail)
        :timer.sleep(250)
      end)

    # We assert either of these log messages because the log changed between elixir
    # versions. It feels like we shouldn't need to assert on the log message but...
    assert log_msg =~ "(stop) bad cast: :fail" || log_msg =~ "but no handle_cast"
    assert :meck.called(HTTPoison, :post, [:_, :_, :_, :_])
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
