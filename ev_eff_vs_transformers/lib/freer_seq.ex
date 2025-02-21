defmodule FreerSeq do
  alias Hallux.Seq

  defmacro op(op), do: quote(do: {E, unquote(op), Seq.new()})
  
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
        {E, unquote(op), unquote(q)} -> {E, unquote(op), Seq.snoc(unquote(q), unquote(k))}
      end
    end
  end

  def liftM(f, m), do: m |> bind(fn x -> pure(f.(x)) end)

  def f ~>> g, do: fn x -> x |> f.() |> bind(g) end

  def run({Pure, x}), do: x
  def run({E, _op, _f}), do: raise("Internal:run - This (E) should never happen")

  def app(q, x) do
    case Seq.view_l(q) do
      nil -> pure(x)
      {h, t} -> case h.(x) do
        {Pure, x} -> app(t, x)
        {E, op, f} -> {E, op, Seq.concat(f, t)}
      end
    end
  end
end

defmodule FreerSeq.State do
  alias Hallux.Seq
  require FreerSeq

  def get, do: FreerSeq.op(Get)

  def put(x), do: FreerSeq.op({Put, x})

  def ours(Get = op), do: {Yes, op}
  def ours({Put, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runState({Pure, x}, s) do FreerSeq.pure({x, s}) end
  def runState({E, op, q}, s) do
    case ours(op) do
      {Yes, Get} -> runState(FreerSeq.app(q, s), s)
      {Yes, {Put, x}} -> runState(FreerSeq.app(q, {}), x)
      {No, other} -> {E, other, Seq.new([fn x -> runState(FreerSeq.app(q, x), s) end])}
    end
  end
end

defmodule FreerSeq.Exception do
  alias Hallux.Seq
  require FreerSeq

  def throw_error(e), do: FreerSeq.op({Error, e})

  def ours({Error, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runException(action) do
    handleRelay(&FreerSeq.pure({Right, &1}), fn {Error, e}, _k -> FreerSeq.pure({Left, e}) end, action)
  end

  def handleRelay(ret, h, action) do
    case action do
      FreerSeq.pure(x) ->
        ret.(x)

      {E, op, q} ->
        k = &FreerSeq.app(q, &1)
        case ours(op) do
          {Yes, x} -> h.(x, k)
          {No, other} -> {E, other, Seq.new([k])}
        end
    end
  end
end
