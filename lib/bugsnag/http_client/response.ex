defmodule Bugsnag.HTTPClient.Response do
  @moduledoc false

  @type t :: %__MODULE__{
          status: non_neg_integer(),
          body: binary(),
          headers: list({binary(), binary()})
        }

  defstruct [
    :body,
    :headers,
    :status
  ]

  def new(status, headers, body) do
    %__MODULE__{
      body: body,
      headers: headers,
      status: status
    }
  end
end
