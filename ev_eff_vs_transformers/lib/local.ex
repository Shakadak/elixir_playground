defmodule B.Local.Op do
  @enforce_keys [:op]
  defstruct @enforce_keys
end

defmodule B.Local do
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

  import Bind
  import Context.CCons
  import Ctl
  import Eff

  def lget, do: %B.Local.Op{op: :lget}
  def lput, do: %B.Local.Op{op: :lput}

  def local(init, action) do
    const = fn x, _ -> x end
    localRet(init, const, action)
  end

  def localGet, do: perform(lget(), {})

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
end

defimpl Context, for: B.Local.Op do
  import Op
  import Ctl

  def appropriate?(_, %B.Local{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(%@for{op: :lget}, %B.Local{local: ref}) do
    op fn _m, _ctx, _x -> unsafeIO(readIORef(ref)) end
  end

  def selectOp(%@for{op: :lput}, %B.Local{local: ref}) do
    op fn _m, _ctx, x -> unsafeIO(writeIORef(ref, x)) end
  end
end

defmodule B.FLocal.Get do
  defstruct []

  require Op

  def appropriate?(_, %impl{}), do: impl == B.FLocal

  def selectOp(_, %_{lget: op}), do: op
  def runOp(_, %_{lget: op}, m, ctx, x), do: op |> Op.runOp(m, ctx, x)
end

defmodule B.FLocal.Put do
  defstruct []

  require Op

  def appropriate?(_, %impl{}), do: impl == B.FLocal

  def selectOp(_, %_{lput: op}), do: op
  def runOp(_, %_{lput: op}, m, ctx, x), do: op |> Op.runOp(m, ctx, x)
end

defmodule B.FLocal do
  @enforce_keys [
    :lget,
    :lput,
  ]
  defstruct @enforce_keys 

  def lget, do: %B.FLocal.Get{}
  def lput, do: %B.FLocal.Put{}
end

defimpl Context, for: B.FLocal.Get do
  def appropriate?(_, %B.FLocal{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %B.FLocal{lget: op}), do: op
end

defimpl Context, for: B.FLocal.Put do
  def appropriate?(_, %B.FLocal{}), do: true
  def appropriate?(_, %_{}), do: false

  def selectOp(_, %B.FLocal{lput: op}), do: op
end
