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
    adapter().post(request)
  end

  defp adapter do
    Application.get_env(:bugsnag, :http_client, HTTPoison)
  end
end
