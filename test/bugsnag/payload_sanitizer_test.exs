defmodule Bugsnag.PayloadSanitizerTest do
  use ExUnit.Case
  alias Bugsnag.Payload
  import ExUnit.CaptureLog

  @moduletag :capture_log

  test "it sanitizes the error message" do
    Application.put_env(:bugsnag, :sanitizers, [
      fn string -> Regex.replace(~r/fail/, string, "pass") end
    ])

    %{
      events: [
        %{exceptions: [%{message: msg}]} | _
      ]
    } = apply(Payload, :new, get_problem_with_error_message("this is a [fail]"))

    assert msg == "this is a [pass]"
  end

  test "it sanitizes the mfa from the error report" do
    Application.put_env(:bugsnag, :sanitizers, [
      fn string -> Regex.replace(~r/fail/, string, "pass") end
    ])

    %{
      events: [
        %{exceptions: [%{stacktrace: [%{method: method} | _]} | _]} | _
      ]
    } = apply(Payload, :new, get_problem("this is a [fail]"))

    assert method == "Harbour.cats(\"this is a [pass]\")"
  end

  test "it replaces the value with a censored value if the sanitization fails" do
    Application.put_env(:bugsnag, :sanitizers, [
      fn _ -> raise "error" end
    ])

    %{
      events: [
        %{exceptions: [%{stacktrace: [%{method: method} | _]} | _]} | _
      ]
    } = apply(Payload, :new, get_problem("this is a [fail]"))

    assert method == "[CENSORED DUE TO SANITIZER EXCEPTION]"
  end

  test "it logs out if the sanitization fails" do
    Application.put_env(:bugsnag, :sanitizers, [
      fn _ -> raise "error" end
    ])

    assert capture_log(fn -> apply(Payload, :new, get_problem("this is a [fail]")) end) =~ "Bugsnag Sanitizer failed to sanitize a value"
  end

  def get_problem(args, options \\ []) do
    Harbour.cats(args)
  rescue
    exception -> [exception, System.stacktrace(), options]
  end

  def get_problem_with_error_message(msg) do
    raise msg
  rescue
    exception -> [exception, System.stacktrace(), []]
  end
end
