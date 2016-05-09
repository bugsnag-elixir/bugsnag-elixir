defmodule Bugsnag do
  use Application

  alias Bugsnag.Payload

  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  def start do
  end

  def report(exception, options \\ []) do
    stacktrace = options[:stacktrace] || System.stacktrace

    spawn fn ->
      Payload.new(exception, stacktrace, options)
        |> to_json
        |> send_notification
    end
  end

  def to_json(payload) do
    payload |> Poison.encode!
  end

  defp send_notification(body) do
    HTTPoison.post @notify_url, body, @request_headers
  end
end
