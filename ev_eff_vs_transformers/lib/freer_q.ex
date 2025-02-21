defmodule FreerQ do

  defmacro __using__([]) do
    quote do
      require unquote(__MODULE__)
    end
  end

  defmacro pure(x), do: {Pure, x}
  defmacro impure(op, q), do: quote(do: {Impure, unquote(op), unquote(q)})

  defmacro op(op) do
    quote do
      impure(unquote(op), :queue.new())
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:pure, :impure])
  end
  
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
        pure(unquote(x)) -> unquote(pure_branch_ast)
        impure(unquote(op), unquote(q)) -> impure(unquote(op), :queue.in(unquote(k), unquote(q)))
      end
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:pure, :impure])
  end

  def liftM(f, m), do: m |> bind(fn x -> pure(f.(x)) end)

  def f ~>> g, do: fn x -> x |> f.() |> bind(g) end

  def run(pure(x)), do: x
  def run(impure(_op, _f)), do: raise("Internal:run - This (E) should never happen")

  def app(q, x) do
    case :queue.out(q) do
      {:empty, _} -> pure(x)
      {{:value, h}, t} -> case h.(x) do
        pure(x) -> app(t, x)
        impure(op, f) -> impure(op, :queue.join(f, t))
      end
    end
  end
end
