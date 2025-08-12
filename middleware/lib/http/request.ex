defmodule Http.Request do
  @enforce_keys [
    :body,
    :headers,
    :method,
    :url
  ]
  defstruct @enforce_keys

  @type t(val) :: %__MODULE__{body: val}

  def default do
    %__MODULE__{
      body: "",
      headers: [],
      method: :get,
      url: %URI{}
    }
  end

  def body(%__MODULE__{} = resp, body) do
    %{resp | body: body}
  end

  def header(%__MODULE__{headers: headers} = req, key, value) do
    %{req | headers: [{key, value} | headers]}
  end

  def method(%__MODULE__{} = resp, method) do
    %{resp | method: method}
  end

  def url(%__MODULE__{} = resp, url) do
    %{resp | url: url}
  end
end
