defmodule Bugsnag.HTTPClient.Request do
  @moduledoc false

  @type t :: %__MODULE__{
          url: String.t(),
          body: iodata(),
          headers: list({binary(), binary()}),
          opts: Keyword.t()
        }

  @default_headers [{"Content-Type", "application/json"}]

  defstruct [
    :url,
    :body,
    :headers,
    :opts
  ]

  def new(body, url, headers \\ [], opts \\ []) do
    %__MODULE__{
      url: url,
      body: body,
      headers: headers ++ @default_headers,
      opts: opts
    }
  end
end
