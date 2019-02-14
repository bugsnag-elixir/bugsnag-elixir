defmodule Bugsnag.PayloadSanitizerTest do
  use ExUnit.Case
  alias Bugsnag.Payload

  test "it sanitizes the error message" do
    Application.put_env(:bugsnag, :sanitizers, [&sanitizer_example_function/1])

    error = apply(Payload, :new, get_problem_with_error_message("this is a [fail]"))
    event = List.first(error.events)
    exception = List.first(event.exceptions)
    assert exception.message == "this is a [pass]"
  end

  test "it sanitizes the mfa from the error report" do
    Application.put_env(:bugsnag, :sanitizers, [&sanitizer_example_function/1])

    error = apply(Payload, :new, get_problem("this is a [fail]"))
    event = List.first(error.events)
    exception = List.first(event.exceptions)
    stacktrace = List.first(exception.stacktrace)
    assert stacktrace.method == "Harbour.cats(\"this is a [pass]\")"
  end

  def get_problem(args) do
    Harbour.cats(args)
  rescue
    exception -> [exception, System.stacktrace(), []]
  end

  def get_problem_with_error_message(msg) do
    raise msg
  rescue
    exception -> [exception, System.stacktrace(), []]
  end

  def sanitizer_example_function(string) do
    Regex.replace(~r/fail/, string, "pass")
  end
end
