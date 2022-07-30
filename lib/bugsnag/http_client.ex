defmodule Bugsnag.HTTPClient do
  @moduledoc """
  A Behavior defining an HTTP Client for Bugsnag
  """
  alias Bugsnag.HTTPClient.Adapters.HTTPoison
  alias Bugsnag.HTTPClient.Request
  alias Bugsnag.HTTPClient.Response

  @type success :: {:ok, Response.t()}
  @type failure :: {:error, reason :: any()}
  @callback post(Request.t()) :: success() | failure()

  def post(request) do
    http_client().post(%{request | opts: http_client_opts() ++ request.opts})
  end

  defp http_client do
    Application.get_env(:bugsnag, :http_client, HTTPoison)
  end

  defp http_client_opts do
    Application.get_env(:bugsnag, :http_client_opts, [])
  end
end
