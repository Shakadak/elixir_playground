defmodule State do
  @enforce_keys [
    :get,
    :put,
  ]
  defstruct @enforce_keys 

  import Eff
  import Local
  import Bind

  def get, do: fn {} -> {:peach} end
  def put, do: fn {} -> {:melba} end

  def state(init, action) do
    handler = %State{
      get: function(fn {} -> perform(lget(), {}) end),
      put: function(fn x -> perform(lput(), x) end),
    }
    handlerLocal(init, handler, action)
  end

  def local(init, action) do
    handler = %Local{
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
    local(init, handlerHide(h, action))
  end

  def state2(init, action) do
    handler = %State{
      get: function(fn {} -> perform(lget(), {}) end),
      put: function(fn x -> perform(lput(), x) end),
    }
    handlerLocal2(init, handler, action)
  end
end
