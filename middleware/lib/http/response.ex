defmodule Http.Response do
  @enforce_keys [
    :body,
    :headers,
    :status
  ]
  defstruct @enforce_keys

  @type t(val) :: %__MODULE__{body: val}

  def default do
    %__MODULE__{
      body: "",
      headers: [],
      status: 0
    }
  end

  def status(%__MODULE__{} = resp, status) do
    %{resp | status: status}
  end

  def header(%__MODULE__{headers: headers} = req, key, value) do
    %{req | headers: [{key, value} | headers]}
  end

  def body(%__MODULE__{} = resp, body) do
    %{resp | status: body}
  end
end
