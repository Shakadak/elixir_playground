defmodule Local.Op do
  @enforce_keys [:op]
  defstruct @enforce_keys

  import Op
  import Ctl

  def appropriate?(_, %impl{}), do: impl == Local

  def lget(_m, _ctx, _x, ref), do: unsafeIO(readIORef(ref))

  def selectOp(%__MODULE__{op: :lget}, %impl{local: ref}) when impl == Local do
    #op fn _m, _ctx, _x -> unsafeIO(readIORef(ref)) end
    op(&__MODULE__.lget(&1, &2, &3, ref))
  end

  def selectOp(%__MODULE__{op: :lput}, %impl{local: ref}) when impl == Local do
    op fn _m, _ctx, x -> unsafeIO(writeIORef(ref, x)) end
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

  import Bind
  import Context.CCons
  import Ctl
  import Eff

  def lget, do: %Local.Op{op: :lget}
  def lput, do: %Local.Op{op: :lput}

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
end

defmodule FLocal.Put do
  defstruct []
end

defmodule FLocal do
  @enforce_keys [
    :lget,
    :lput,
  ]
  defstruct @enforce_keys 

  def lget, do: %FLocal.Get{}
  def lput, do: %FLocal.Put{}
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
