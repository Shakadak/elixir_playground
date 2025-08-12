defmodule Http.Builder do
  alias Http.Middleware
  alias Http.Request
  alias Http.Response

  @enforce_keys [
    :format_req,
    :format_resp,
    :options,
    :private,
    :step_req,
    :step_resp
  ]
  defstruct @enforce_keys

  def default do
    Middleware.identity()
  end

  def post do
    Middleware.on_request(fn %Request{} = req ->
      %{req | method: :post}
    end)
  end

  def get do
    Middleware.on_request(fn %Request{} = req ->
      %{req | method: :get}
    end)
  end

  def put do
    Middleware.on_request(fn %Request{} = req ->
      %{req | method: :put}
    end)
  end

  def delete do
    Middleware.on_request(fn %Request{} = req ->
      %{req | method: :delete}
    end)
  end

  def path(path) do
    Middleware.on_request(fn %Request{url: %URI{} = url} = req ->
      %{req | url: %{url | path: path}}
    end)
  end

  def query(query) do
    Middleware.on_request(fn %Request{url: %URI{} = url} = req ->
      %{req | url: %{url | query: query}}
    end)
  end

  def header(key, value) do
    Middleware.on_request(fn %Request{headers: headers} = req ->
      %{req | headers: [{key, value} | headers]}
    end)
  end

  def body(body) do
    Middleware.on_request(fn %Request{} = req ->
      %{req | body: body}
    end)
  end

  def query_param(key, value) do
    Middleware.on_request(fn %Request{url: %URI{query: query} = url} = req ->
      query =
        URI.decode_query(query)
        |> Map.put(key, value)
        |> URI.encode_query()

      %{req | url: %{url | query: query}}
    end)
  end

  def serialize_with(content_type, serializer!) do
    Middleware.on_request(fn %Request{} = req ->
      %{req | body: serializer!.(req.body)}
    end)
    |> Middleware.compose(header("content-type", content_type))
  end

  def deserialize_with(deserializer!) do
    Middleware.on_response(
      &case &1 do
        {:ok, %Response{} = resp} -> %{resp | body: deserializer!.(resp.body)}
        {:error, err} -> {:error, err}
      end
    )
  end

  def json do
    json_req()
    |> Middleware.compose(json_resp())
  end

  def json_req do
    json_module = Application.fetch_env!(:kbrw_sdk_iam, :json_module)
    serialize_with("application/json", &json_module.encode!/1)
  end

  def json_resp do
    json_module = Application.fetch_env!(:kbrw_sdk_iam, :json_module)
    deserialize_with(&json_module.decode!/1)
  end

  def www_form_req do
    serialize_with("application/x-www-form-urlencoded", &URI.encode_query/1)
  end
end
