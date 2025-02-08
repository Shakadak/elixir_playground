defmodule Ctl.Pure do
  @enforce_keys [
    :result,
  ]
  defstruct @enforce_keys

  defmacro _pure(result) do
    quote do
      %unquote(__MODULE__){
        result: unquote(result),
      }
    end
  end
end

defmodule Ctl.Yield do
  @enforce_keys [
    :marker,
    :op,
    :cont,
  ]
  defstruct @enforce_keys

  defmacro _yield(marker, op, cont) do
    quote do
      %unquote(__MODULE__){
        marker: unquote(marker),
        op: unquote(op),
        cont: unquote(cont),
      }
    end
  end
end

defmodule Ctl do
  import Ctl.Pure, only: [
    _pure: 1,
  ]
  import Ctl.Yield, only: [
    _yield: 3,
  ]

  import Bind

  def yield(m, op) do
    _yield(m, op, &_pure/1)
  end

  def kcompose(g, f, x), do: bind(f.(x), g)

  def pure(x), do: _pure(x)

  def bind(_pure(x), f), do: f.(x)
  def bind(_yield(m, op, cont), f), do: _yield(m, op, &kcompose(f, cont, &1))

  def prompt(action) do
    freshMarker(fn m ->
      mprompt(m, action.(m))
    end)
  end

  def runCtl(_pure(x)), do: x
  def runCtl(_yield(_, _, _) = m), do: raise "unhandled operation : #{inspect(m)}" # only if marker escapes the scope of the prompt

  def mprompt(_m, _pure(x)), do: _pure(x)
  def mprompt(m, _yield(n, op, cont)) do
    cont_ = fn x ->
      mprompt(m, cont.(x))
    end
    case mmatch(m, n) do
      Nothing -> _yield(n, op, cont_) # Keep yielding
      {Just, Refl} -> op.(cont_)
    end
  end

  def freshMarker(f) do
    m = :erlang.unique_integer([:positive, :monotonic])
    f.({Marker, m})
  end

  # Might be wrong, looks like it just want to check if it is of the same type.
  def mmatch({Marker, m}, {Marker, m}), do: {Just, Refl}
  def mmatch({Marker, _}, {Marker, _}), do: Nothing

  def unsafePromptIORef(init, action) do
    freshMarker fn m ->
      m Ctl do
        r <- unsafeIO(newIORef(init))
        mpromptIORef(r, action.(m, r))
      end
    end
  end

  def newIORef(init) do
    tid = :ets.new(nil, [:public])
    true = :ets.insert(tid, {:ref, init})
    tid
  end

  def readIORef(ref) do
    :ets.lookup_element(ref, :ref, 2)
  end

  def writeIORef(ref, val) do
    true = :ets.insert(ref, {:ref, val})
  end

  def unsafeIO(ref) do
    Ctl.pure(ref)
  end

  def mpromptIORef(r, action) do
    case action do
      _pure(_) = p -> p
      _yield(m, op, cont) ->
        m Ctl do
          val <- unsafeIO(readIORef(r))
          cont_ = fn x -> m Ctl do
            unsafeIO(writeIORef(r, val))
            mpromptIORef(r, cont.(x))
          end end
          _yield(m, op, cont_)
        end
    end
  end

  ### Bind

  def _Bind(m, f), do: bind(m, f)
end
