defmodule Bugsnag.HTTPClient.Response do
  @moduledoc false

  @type t :: %__MODULE__{
          status: non_neg_integer(),
          body: String.t(),
          headers: list({String.t(), String.t()})
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
