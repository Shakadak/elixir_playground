defmodule FreerQ.State do
  require FreerQ

  defmacro __using__([]) do
    quote do
      require FreerQ
      require unquote(__MODULE__)
    end
  end

  defmacro get, do: quote(do: FreerQ.op(Get))

  defmacro put(x), do: quote(do: FreerQ.op({Put, unquote(x)}))

  def runState(FreerQ.pure(x), s) do FreerQ.pure({x, s}) end
  def runState(FreerQ.impure(op, q), s) do
    case op do
      Get -> runState(FreerQ.app(q, s), s)
      {Put, x} -> runState(FreerQ.app(q, {}), x)
      other -> FreerQ.impure(other, :queue.from_list([fn x -> runState(FreerQ.app(q, x), s) end]))
    end
  end
end
