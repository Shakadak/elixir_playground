defmodule State.Get do
  defstruct []
end

defmodule State.Put do
  defstruct []
end

defmodule State do
  @enforce_keys [
    :get,
    :put,
  ]
  defstruct @enforce_keys 

  import Local

  use Eff

  def get, do: %State.Get{}
  def put, do: %State.Put{}

  def state(init, action) do
    handler = %State{
      get: function(fn {} -> perform(lget(), {}) end),
      put: function(fn x -> perform(lput(), x) end),
    }
    handlerLocal(init, handler, action)
  end

  def local2(init, action) do
    handler = %FLocal{
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
    handler = %State{
      get: function(fn {} -> perform(FLocal.lget(), {}) end),
      put: function(fn x -> perform(FLocal.lput(), x) end),
    }
    handlerLocal2(init, handler, action)
  end
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
