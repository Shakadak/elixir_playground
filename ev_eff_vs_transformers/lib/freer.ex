defmodule Freer do
  alias Hallux.Seq

  defmacro op(op), do: quote(do: {E, unquote(op), Seq.new()})
  
  defmacro pure(x), do: {Pure, x}

  defmacro bind(action, k) do
    quote generated: true do
      case unquote(action) do
        {Pure, x} -> unquote(k).(x)
        {E, op, f} -> {E, op, Seq.snoc(f, unquote(k))}
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

defmodule Freer.State do
  alias Hallux.Seq
  require Freer

  def get, do: Freer.op(Get)

  def put(x), do: Freer.op({Put, x})

  def ours(Get = op), do: {Yes, op}
  def ours({Put, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runState({Pure, x}, s) do Freer.pure({x, s}) end
  def runState({E, op, q}, s) do
    case ours(op) do
      {Yes, Get} -> runState(Freer.app(q, s), s)
      {Yes, {Put, x}} -> runState(Freer.app(q, {}), x)
      {No, other} -> {E, other, Seq.new([fn x -> runState(Freer.app(q, x), s) end])}
    end
  end
end

defmodule Freer.Exception do
  alias Hallux.Seq
  require Freer

  def throw_error(e), do: Freer.op({Error, e})

  def ours({Error, _} = op), do: {Yes, op}
  def ours(other), do: {No, other}

  def runException(action) do
    handleRelay(&Freer.pure({Right, &1}), fn {Error, e}, _k -> Freer.pure({Left, e}) end, action)
  end

  def handleRelay(ret, h, action) do
    case action do
      Freer.pure(x) ->
        ret.(x)

      {E, op, q} ->
        k = &Freer.app(q, &1)
        case ours(op) do
          {Yes, x} -> h.(x, k)
          {No, other} -> {E, other, Seq.new([k])}
        end
    end
  end
end
