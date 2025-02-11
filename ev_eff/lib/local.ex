defmodule Local.Op do
  @enforce_keys [:op]
  defstruct @enforce_keys

  import Op
  import Ctl

  def appropriate?(_, %impl{}), do: impl == Local

  def runOp(%__MODULE__{op: :lget}, %_{local: ref}, _m, _ctx, _x) do
    unsafeIO(readIORef(ref))
  end

  def runOp(%__MODULE__{op: :lput}, %_{local: ref}, _m, _ctx, x) do
    unsafeIO(writeIORef(ref, x))
  end
end

defmodule Local do
  @enforce_keys [
    :local,
  ]
  defstruct @enforce_keys 

  defmacro local(io_ref) do
    quote do
      %unquote(__MODULE__){
        local: unquote(io_ref)
      }
    end
  end

  use Eff
  import Context.CCons
  import Ctl

  def lget, do: %Local.Op{op: :lget}
  def lput, do: %Local.Op{op: :lput}

  def local(init, action) do
    const = fn x, _ -> x end
    localRet(init, const, action)
  end

  def localGet, do: perform(lget(), {})
  def localPut(x), do: perform(lput(), x)

  def localRet(init, ret, action) do
    eff fn ctx ->
      unsafePromptIORef init, fn m, r ->
        m Ctl do
          x <- Eff.under(ccons(m, local(r), & &1, ctx), action)
          y <- unsafeIO(readIORef(r))
          Ctl.pure(ret.(x, y))
        end
      end
    end
  end

  def handlerLocal(init, h, action) do
    local(init, handlerHide(h, action))
  end

  def handlerLocalRet(init, ret, h, action) do
    ret = fn x ->
      m Eff do
        y <- localGet()
        Eff.pure(ret.(x, y))
      end
    end

    action = handlerHideRetEff(ret, h, action)

    local(init, action)
  end
end

defimpl Context, for: Local.Op do
  import Op
  import Ctl

  def appropriate?(_, %Local{}), do: true
  def appropriate?(_, %_{}), do: false

  def lget(_m, _ctx, _x, ref), do: unsafeIO(readIORef(ref))

  def selectOp(%@for{op: :lget}, %Local{local: ref}) do
    #op fn _m, _ctx, _x -> unsafeIO(readIORef(ref)) end
    op(&__MODULE__.lget(&1, &2, &3, ref))
  end

  def selectOp(%@for{op: :lput}, %Local{local: ref}) do
    op fn _m, _ctx, x -> unsafeIO(writeIORef(ref, x)) end
  end
end

defmodule FLocal.Get do
  defstruct []

  require Op

  def appropriate?(_, %impl{}), do: impl == FLocal

  def selectOp(_, %_{lget: op}), do: op
  def runOp(_, %_{lget: op}, m, ctx, x), do: Op.runOp(op, m, ctx, x)
end

defmodule FLocal.Put do
  defstruct []

  require Op

  def appropriate?(_, %impl{}), do: impl == FLocal

  def selectOp(_, %_{lput: op}), do: op
  def runOp(_, %_{lput: op}, m, ctx, x), do: Op.runOp(op, m, ctx, x)
end

defmodule FLocal do
  @enforce_keys [
    :lget,
    :lput,
  ]
  defstruct @enforce_keys 

  use Eff

  def handler do
   %FLocal{
     lget: operation(fn {}, k -> pure(fn s -> m Eff do r <- k.(s) ; r.(s) end end) end),
     lput: operation(fn s, k -> pure(fn _ -> m Eff do r <- k.({}) ; r.(s) end end) end),
   }
  end

  def lget, do: %FLocal.Get{}
  def lput, do: %FLocal.Put{}

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

  #def state2(init, action) do
  #  handler = %FState{
  #    get: function(fn {} -> perform(FLocal.lget(), {}) end),
  #    put: function(fn x -> perform(FLocal.lput(), x) end),
  #  }
  #  handlerLocal2(init, handler, action)
  #end
end

defimpl Context, for: FLocal.Get do
  def appropriate?(_, %FLocal{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %FLocal{lget: op}), do: op
end

defimpl Context, for: FLocal.Put do
  def appropriate?(_, %FLocal{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %FLocal{lput: op}), do: op
end
