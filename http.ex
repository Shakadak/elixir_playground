defmodule Http do
  @moduledoc """
  Facilities for httpc.
  """

  def get(url, opts \\ []) do
    request(Enum.into(opts, method: :get, url: url))
  end

  def post(url, opts \\ []) do
    request(Enum.into(opts, method: :post, url: url))
  end

  def post(url, content_type, payload, opts \\ []) do
    request(Enum.into(opts, method: :post, url: url, content_type: content_type, payload: payload))
  end

  def put(url, opts \\ []) do
    request(Enum.into(opts, method: :put, url: url))
  end

  def put(url, content_type, payload, opts \\ []) do
    request(Enum.into(opts, method: :put, url: url, content_type: content_type, payload: payload))
  end

  def request(opts) do
    method = fetch!(opts, :method)
    url = fetch!(opts, :url)
    headers = Access.get(opts, :headers, [])
    content_type = Access.get(opts, :content_type, '')
    payload = Access.get(opts, :payload, "")
    http_options = Access.get(opts, :http_options, [])
    options = Access.get(opts, :options, [])

    request =
      case {to_charlist(content_type), payload} do
        {'', ""} -> {url, headers}
        {content_type, payload} -> {url, headers, content_type, payload}
      end

    case :httpc.request(method, request, http_options, options) do
      {:error, _} = x ->
        x

      {:ok, {status_code, body}} ->
        result = %{status_code: status_code, body: body}
        {:ok, result}

      {:ok, {{_, status_code, reason_phrase}, headers, body}} ->
        result = %{
          status_code: status_code,
          reason_phrase: reason_phrase,
          headers: headers,
          body: body
        }

        {:ok, result}
    end
  end

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  def fetch!(t, k) do
    case Access.fetch(t, k) do
      {:ok, y} -> y
      :error -> raise(KeyError, key: k, term: t)
    end
  end
end
