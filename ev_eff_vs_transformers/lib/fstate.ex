#defmodule Flocal.Op do
#  defstruct [:op]
#
#  use Eff
#
#  def appropriate?(_, %impl{}), do: impl == Flocal
#
#  def runOp(%__MODULE__{op: :get}, _, m, ctx, x) do
#    op = fn {}, k ->
#      pure(fn s ->
#        m Eff do
#          r <- k.(s)
#          r.(s)
#        end
#      end)
#    end
#    operation(op)
#    |> Op.runOp(m, ctx, x)
#  end
#
#  def runOp(%__MODULE__{op: :put}, _, m, ctx, x) do
#    operation(fn s, k ->
#      pure(fn _ ->
#        m Eff do
#          r <- k.({})
#          r.(s)
#        end
#      end)
#    end)
#    |> Op.runOp(m, ctx, x)
#  end
#end

defmodule Flocal do
  defstruct []

  use Eff

  def get(ccons(m, h, t, sub_ctx), x) do
    case h do
      %Flocal{} ->
        operation(fn {}, k ->
          pure(fn s ->
            m Eff do
              r <- k.(s)
              r.(s)
            end
          end)
        end)
        |> Op.runOp(m, t.(sub_ctx), x)

      _ -> get(sub_ctx, x)
    end
  end

  def put(ccons(m, h, t, sub_ctx), x) do
    case h do
      %Flocal{} ->
        operation(fn s, k ->
          pure(fn _ ->
            m Eff do
              r <- k.({})
              r.(s)
            end
          end)
        end)
        |> Op.runOp(m, t.(sub_ctx), x)

        _ -> put(sub_ctx, x)
    end
  end

  defmacro get,    do: quote(do: perform(&Flocal.get/2, {}))
  defmacro put(x), do: quote(do: perform(&Flocal.put/2, unquote(x)))

  #def get,    do: perform(&get/2, {})
  #def put(x), do: perform(&put/2, x )

  def local(init, action) do
    handler = %__MODULE__{}

    action = handler(handler, m Eff do
      x <- action
      pure(fn _s ->
        pure(x)
      end)
    end)

    m Eff do
      f <- action
      f.(init)
    end
  end

  def handlerLocal(init, h, action) do
    local(init, handlerHide(h, action))
  end
end

#defmodule Fstate.Op do
#  defstruct [:op]
#
#  use Eff
#
#  def appropriate?(_, %impl{}), do: impl == Fstate
#
#  def runOp(%__MODULE__{op: :get}, _, m, ctx, x) do
#    function(fn {} -> Flocal.get() end)
#    |> Op.runOp(m, ctx, x)
#  end
#
#  def runOp(%__MODULE__{op: :put}, _, m, ctx, x) do
#    function(&Flocal.put/1)
#    |> Op.runOp(m, ctx, x)
#  end
#end

#defmodule Fstate do
#  defstruct []
#
#  use Eff
#
#  def get,    do: perform(%Fstate.Op{op: :get}, {})
#  def put(x), do: perform(%Fstate.Op{op: :put}, x )
#
#  def state(init, action) do
#    handler = %__MODULE__{}
#    Flocal.handlerLocal(init, handler, action)
#  end
#
#  def local2(init, action) do
#    handler = %FLocal{
#      lget: operation(fn {}, k -> pure(fn s -> m Eff do r <- k.(s) ; r.(s) end end) end),
#      lput: operation(fn s, k -> pure(fn _ -> m Eff do r <- k.({}) ; r.(s) end end) end),
#    }
#    m Eff do
#      f <- handler(handler, m Eff do
#        x <- action
#        pure(fn _s -> pure(x) end)
#      end)
#      f.(init)
#    end
#  end
#
#  def handlerLocal2(init, h, action) do
#    local2(init, handlerHide(h, action))
#  end
#
#  #def state2(init, action) do
#  #  handler = %FState{
#  #    get: function(fn {} -> perform(FLocal.lget(), {}) end),
#  #    put: function(fn x -> perform(FLocal.lput(), x) end),
#  #  }
#  #  handlerLocal2(init, handler, action)
#  #end
#end
