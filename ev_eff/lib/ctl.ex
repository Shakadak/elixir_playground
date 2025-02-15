defmodule Ctl.Pure do
  @keys [
    :result,
  ]
  defstruct @keys
end

defmodule Ctl.Yield do
  @keys [
    :marker,
    :op,
    :cont,
  ]
  defstruct @keys
end

defmodule Ctl do

  defmacro _yield(marker, op, cont) do
    quote do
      {
        unquote(__MODULE__.Yield),
        unquote(marker),
        unquote(op),
        unquote(cont),
      }
    end
    #|> tap(&IO.puts("_yield: " <> Macro.to_string(&1)))
  end

  defmacro _pure(result) do
    quote do
      {
        unquote(__MODULE__.Pure),
        unquote(result),
      }
    end
  end

  defmacro yield(banana, split) do
    quote do
      _yield(unquote(banana), unquote(split), &_pure/1)
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:_yield, :_pure])
    #|> tap(&IO.inspect(&1))
    #|> tap(&IO.puts("yield: " <> Macro.to_string(&1)))
  end

  #def kcompose(g, f, x), do: f.(x) |> bind(g)

  def kcompose(g, f, x) do
    case f.(x) do
      _pure(x) -> g.(x)
      _yield(m, op, cont) -> _yield(m, op, &kcompose(g, cont, &1))
    end
  end

  defmacro pure(x) do
    quote do
      _pure(unquote(x))
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:_pure])
  end

  # defmacro pure(x) do
  #   quote do

  #     _pure(unquote(x))
  #   end
  # end

  # @compile {:inline, bind: 2}
  # def bind(m, f) do
  #   case m do
  #     _pure(x) -> f.(x)
  #     _yield(m, op, cont) -> _yield(m, op, &kcompose(f, cont, &1))
  #   end
  # end

  require Eff.Internal

  defmacro bind(m, f) do
    x = Macro.unique_var(:x, __MODULE__)
    marker = Macro.unique_var(:m, __MODULE__)
    op = Macro.unique_var(:op, __MODULE__)
    cont = Macro.unique_var(:cont, __MODULE__)

    pure_branch_ast = case Eff.Internal.convert_fn(x, f) do
      {:raw, ast} -> ast
      {:fn, ast} -> quote do unquote(ast).(unquote(x)) end
    end

    quote generated: true do
      case unquote(m) do
        _pure(unquote(x)) -> unquote(pure_branch_ast)
        _yield(unquote(marker), unquote(op), unquote(cont)) -> _yield(unquote(marker), unquote(op), &kcompose(unquote(f), unquote(cont), &1))
      end
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:_pure, :_yield, :kcompose])
  end

  defmacro bind_pure(m, f) do
    x = Macro.unique_var(:x, __MODULE__)
    quote do
      case unquote(m) do
        _pure(unquote(x)) -> unquote(f).(unquote(x))
      end
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:_pure, :_yield, :kcompose])
  end

  defmacro unsafeIO(ref) do
    quote do
      _pure(unquote(ref))
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:_pure])
  end

  defmacro readIORef(ref) do
    quote do
      :ets.lookup_element(unquote(ref), :ref, 2)
    end
  end

  defmacro writeIORef(ref, val) do
    quote do
    true = :ets.insert(unquote(ref), {:ref, unquote(val)})
    end
  end

  #def bind(_pure(x), f), do: f.(x)
  #def bind(_yield(m, op, cont), f), do: _yield(m, op, &kcompose(f, cont, &1))

  def prompt(action) do
    freshMarker(fn m ->
      ctl_val = action.(m)
      mprompt(m, ctl_val)
    end)
  end

  def runCtl(_pure(x)), do: x
  def runCtl(_yield(_, _, _) = m), do: raise "unhandled operation : #{inspect(m)}" # only if marker escapes the scope of the prompt

  def mprompt(_m, _pure(x)), do: _pure(x)
  def mprompt(m, _yield(n, op, cont)) do
    cont_ = fn x ->
      ctl_val = cont.(x)
      mprompt(m, ctl_val)
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
      unsafeIO(newIORef(init))
      |> bind_pure(fn r -> 
        mpromptIORef(r, action.(m, r))
      end)
    end
  end

  def newIORef(init) do
    tid = :ets.new(nil, [:public])
    true = :ets.insert(tid, {:ref, init})
    tid
  end

  def mpromptIORef(r, action) do
    case action do
      _pure(_) = p -> p
      _yield(m, op, cont) ->
        unsafeIO(readIORef(r)) |> bind_pure(fn val ->
          cont_ = fn x ->
            unsafeIO(writeIORef(r, val)) |> bind_pure(fn _ ->
              mpromptIORef(r, cont.(x))
            end)
          end

          _yield(m, op, cont_)
        end)
    end
  end

  ### Bind

  defmacro _Bind(m, f) do
    quote do
      bind(unquote(m), unquote(f))
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:bind])
  end

  ###
end
