defmodule State.Get do
  defstruct []

  import Op

  def appropriate?(_, %impl{}), do: impl == State

  def runOp(_, %_{get: op(op)}, m, ctx, x), do: op.(m, ctx, x)
end

defmodule State.Put do
  defstruct []

  import Op

  def appropriate?(_, %impl{}), do: impl == State
  def appropriate?(_, %impl{}), do: impl == State
  def runOp(_, %_{put: op(op)}, m, ctx, x), do: op.(m, ctx, x)
end

defmodule State do
  @enforce_keys [
    :get,
    :put,
  ]
  defstruct @enforce_keys 

  import Local

  use Eff

  def get(ccons(m, h, t, sub_ctx), x) do
    case h do
      %State{} ->
        function(fn {} -> perform(lget(), {}) end)
        |> Op.runOp(m, t.(sub_ctx), x)

        _ -> get(sub_ctx, x)
    end
  end

  def put(ccons(m, h, t, sub_ctx), x) do
    case h do
      %State{} ->
        function(fn x -> perform(lput(), x) end)
        |> Op.runOp(m, t.(sub_ctx), x)

        _ -> get(sub_ctx, x)
    end
  end

  def get, do: &get/2
  def put, do: &put/2

  def state(init, action) do
    handler = %State{
      get: function(fn {} -> perform(lget(), {}) end),
      put: function(fn x -> perform(lput(), x) end),
    }
    handlerLocal(init, handler, action)
  end

  def appropriate?(_, %State{}), do: true
  def appropriate?(_, %_{}), do: false
end

defimpl Context, for: State.Get do
  def appropriate?(_, %State{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %State{get: op}), do: op
end

defimpl Context, for: State.Put do
  def appropriate?(_, %State{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %State{put: op}), do: op
end
