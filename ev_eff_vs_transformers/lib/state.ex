defmodule B.State.Get do
  require Op
  defstruct []

  def appropriate?(_, %impl{}), do: impl == B.State

  def selectOp(_, %_{get: op}), do: op

  def runOp(_, %_{get: op}, m, ctx, x), do: op |> Op.runOp(m, ctx, x)
end

defmodule B.State.Put do
  require Op
  defstruct []

  def appropriate?(_, %impl{}), do: impl == B.State

  def selectOp(_, %_{put: op}), do: op

def runOp(_, %_{put: op}, m, ctx, x), do: op |> Op.runOp(m, ctx, x)
end

defmodule B.State do
  @enforce_keys [
    :get,
    :put,
  ]
  defstruct @enforce_keys 

  import Local

  use Eff

  def get, do: %B.State.Get{}
  def put, do: %B.State.Put{}

  def state(init, action) do
    handler = %B.State{
      get: function(fn {} -> perform(lget(), {}) end),
      put: function(fn x -> perform(lput(), x) end),
    }
    handlerLocal(init, handler, action)
  end

  def local2(init, action) do
    handler = %B.FLocal{
      lget: operation(fn {}, k -> pure(fn s -> m Eff do r <- k.(s) ; r.(s) end end) end),
      lput: operation(fn s, k -> pure(fn _ -> m Eff do r <- k.({}) ; r.(s) end end) end),
    }
    m Eff do
      f <- handler(handler, m Eff do
        x <- action
        pure(fn _s -> pure(x) end)
      end)
      f.(init)
    end
  end

  def handlerLocal2(init, h, action) do
    local2(init, handlerHide(h, action))
  end

  def state2(init, action) do
    handler = %B.State{
      get: function(fn {} -> perform(B.FLocal.lget(), {}) end),
      put: function(fn x -> perform(B.FLocal.lput(), x) end),
    }
    handlerLocal2(init, handler, action)
  end
end

defimpl Context, for: B.State.Get do
  def appropriate?(_, %State{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %B.State{get: op}), do: op
end

defimpl Context, for: B.State.Put do
  def appropriate?(_, %B.State{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %B.State{put: op}), do: op
end
