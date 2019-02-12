defmodule Bugsnag.Sanitizer do
  def sanitize(string, sanitizers) when is_bitstring(string) do
    Enum.reduce(sanitizers, string, fn fun, s -> fun.(s) end)
  end
end
