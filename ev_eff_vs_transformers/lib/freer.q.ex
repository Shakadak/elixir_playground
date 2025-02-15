defmodule Freer.Q do
  defmacro op(op), do: quote(do: {E, unquote(op), :queue.new()})
  
  defmacro pure(x), do: {Pure, x}

  defmacro bind(action, k) do
    x = Macro.unique_var(:x, __MODULE__)
    op = Macro.unique_var(:op, __MODULE__)
    q = Macro.unique_var(:q, __MODULE__)

    pure_branch_ast =
      Eff.Internal.convert_fn(x, k)
      |> case do
        {:raw, ast} -> ast
        {:fn, _ast} -> quote(do: unquote(k).(unquote(x)))
      end

    quote generated: true do
      case unquote(action) do
        {Pure, unquote(x)} -> unquote(pure_branch_ast)
        {E, unquote(op), unquote(q)} -> {E, unquote(op), :queue.in(unquote(k), unquote(q))}
      end
    end
  end

  def liftM(f, m), do: m |> bind(fn x -> pure(f.(x)) end)

  def f ~>> g, do: fn x -> x |> f.() |> bind(g) end

  def run({Pure, x}), do: x
  def run({E, _op, _f}), do: raise("Internal:run - This (E) should never happen")

  def app(q, x) do
    case :queue.out(q) do
      {:empty, _} -> pure(x)
      {{:value, h}, t} -> case h.(x) do
        {Pure, x} -> app(t, x)
        {E, op, f} -> {E, op, :queue.join(f, t)}
      end
    end
  end
end

defmodule Freer.Q.State do
  require Freer.Q

  def get, do: Freer.Q.op(Get)

  def put(x), do: Freer.Q.op({Put, x})

  def ours(Get = op), do: {Yes, op}
  def ours({Put, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runState({Pure, x}, s) do Freer.Q.pure({x, s}) end
  def runState({E, op, q}, s) do
    case ours(op) do
      {Yes, Get} -> runState(Freer.Q.app(q, s), s)
      {Yes, {Put, x}} -> runState(Freer.Q.app(q, {}), x)
      {No, other} -> {E, other, :queue.from_list([fn x -> runState(Freer.Q.app(q, x), s) end])}
    end
  end
end

defmodule Freer.Q.Exception do
  require Freer.Q

  def throw_error(e), do: Freer.Q.op({Error, e})

  def ours({Error, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runException(action) do
    handleRelay(&Freer.Q.pure({Right, &1}), fn {Error, e}, _k -> Freer.Q.pure({Left, e}) end, action)
  end

  def handleRelay(ret, h, action) do
    case action do
      Freer.Q.pure(x) ->
        ret.(x)

      {E, op, q} ->
        k = &Freer.Q.app(q, &1)
        case ours(op) do
          {Yes, x} -> h.(x, k)
          {No, other} -> {E, other, :queue.from_list([k])}
        end
    end
  end
end
