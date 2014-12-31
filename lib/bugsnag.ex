defmodule Bugsnag do
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  alias Bugsnag.Payload
  use HTTPoison.Base

  def report(exception, options \\ []) do
    spawn fn ->
      post(@notify_url,
           Payload.new(exception, System.stacktrace, options) |> to_json,
           @request_headers)
    end
  end

  def to_json(payload) do
    payload
    |> JSX.encode
    |> elem(1)
  end
end
