defmodule Bugsnag.SanitizerTest do
  use ExUnit.Case
  import Bugsnag.Sanitizer

  test "the sanatizer does nothing with an empty list of sanitizers" do
    assert sanitize("test", []) == "test"
  end

  test "the sanitizer will run a provided functions" do
    fun = fn word -> Regex.replace(~r/fail/, word, "pass") end

    assert sanitize("test-fail-test", [fun]) == "test-pass-test"
  end

  test "the sanitizer will run a list of provided functions" do
    fun1 = fn word -> Regex.replace(~r/fail1/, word, "pass1") end
    fun2 = fn word -> Regex.replace(~r/fail2/, word, "pass2") end

    assert sanitize("test-fail1-fail2-test", [fun1, fun2]) == "test-pass1-pass2-test"
  end
end
