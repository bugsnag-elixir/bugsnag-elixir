if Code.ensure_loaded?(HTTPoison) do
  defmodule Bugsnag.HTTPClient.Adapters.HTTPoison do
    @moduledoc """
    HTTPoison adapter for Bugsnag.HTTPClient
    """
    alias Bugsnag.HTTPClient
    alias Bugsnag.HTTPClient.Request
    alias Bugsnag.HTTPClient.Response

    @behaviour HTTPClient

    @impl true
    def post(%Request{} = request) do
      configuration = Application.get(:bugsnag, __MODULE__, [])
      additional_opts = Keyword.get(configuration, :additional_opts, [])

      request.url
      |> HTTPoison.post(request.body, request.headers, request.opts ++ additional_opts)
      |> case do
        {:ok, %{body: body, headers: headers, status_code: status}} ->
          {:ok, Response.new(status, headers, body)}

        {:error, %{reason: reason}} ->
          {:error, reason}

        _ ->
          {:error, :unknown}
      end
    end
  end
end
