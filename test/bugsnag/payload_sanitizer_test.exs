defmodule Bugsnag.PayloadSanitizerTest do
  use ExUnit.Case
  alias Bugsnag.Payload
  import ExUnit.CaptureLog

  @moduletag :capture_log

  defmodule Sanitizers do
    def fail_to_pass(string) do
      Regex.replace(~r/fail/, string, "pass")
    end

    def raise_fail(_) do
      raise "this is a [fail]"
    end
  end

  test "it sanitizes an error with a secret value" do
    Application.put_env(:bugsnag, :sanitizer, {Sanitizers, :fail_to_pass})

    failure = fn ->
      try do
        raise "123fail123"
      rescue
        exception -> [exception, __STACKTRACE__, []]
      end
    end

    %{
      events: [
        %{exceptions: [%{message: msg}]} | _
      ]
    } = apply(Payload, :new, failure.())

    assert msg == "123pass123"
  end

  test "it sanitizes the error message" do
    Application.put_env(:bugsnag, :sanitizer, {Sanitizers, :fail_to_pass})

    %{
      events: [
        %{exceptions: [%{message: msg}]} | _
      ]
    } = apply(Payload, :new, get_problem_with_error_message("this is a [fail]"))

    assert msg == "this is a [pass]"
  end

  test "it sanitizes the mfa from the error report" do
    Application.put_env(:bugsnag, :sanitizer, {Sanitizers, :fail_to_pass})

    %{
      events: [
        %{exceptions: [%{stacktrace: [%{method: method} | _]} | _]} | _
      ]
    } = apply(Payload, :new, get_problem("this is a [fail]"))

    assert method == "Harbour.cats(\"this is a [pass]\")"
  end

  test "it replaces the value with a censored value if the sanitization fails" do
    Application.put_env(:bugsnag, :sanitizer, {Sanitizers, :raise_fail})

    %{
      events: [
        %{exceptions: [%{stacktrace: [%{method: method} | _]} | _]} | _
      ]
    } = apply(Payload, :new, get_problem("this is a [fail]"))

    assert method == "[CENSORED DUE TO SANITIZER EXCEPTION]"
  end

  test "it logs out if the sanitization fails" do
    Application.put_env(:bugsnag, :sanitizer, {Sanitizers, :raise_fail})

    assert capture_log(fn -> apply(Payload, :new, get_problem("this is a [fail]")) end) =~
             "Bugsnag Sanitizer failed to sanitize a value"
  end

  def get_problem(args, options \\ []) do
    Module.concat(Elixir, "Harbour").cats(args)
  rescue
    exception -> [exception, __STACKTRACE__, options]
  end

  def get_problem_with_error_message(msg) do
    raise msg
  rescue
    exception -> [exception, __STACKTRACE__, []]
  end
end
