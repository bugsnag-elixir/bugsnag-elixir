defmodule Bugsnag do
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  alias Bugsnag.Payload
  use HTTPoison.Base

  def report(exception, options \\ []) do
    stacktrace = Keyword.get(options, :custom_stacktrace) || System.stacktrace
    payload = Payload.new(exception, stacktrace, options) |> to_json

    spawn fn ->
      post(@notify_url, payload, @request_headers)
    end
  end

  def to_json(payload) do
    payload
    |> Poison.encode!
  end
end
