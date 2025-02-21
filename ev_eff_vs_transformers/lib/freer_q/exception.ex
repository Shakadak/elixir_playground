defmodule FreerQ.Exception do
  require FreerQ

  defmacro __using__([]) do
    quote do
      require FreerQ
      require unquote(__MODULE__)
    end
  end

  def throw_error(e), do: FreerQ.op({Error, e})

  def runException(action) do
    handleRelay(&FreerQ.pure({Right, &1}), fn {Error, e}, _k -> FreerQ.pure({Left, e}) end, action)
  end

  def handleRelay(ret, h, action) do
    case action do
      FreerQ.pure(x) ->
        ret.(x)

      FreerQ.impure(op, q) ->
        k = &FreerQ.app(q, &1)
        case op do
          {Error, _} = x -> h.(x, k)
          other -> FreerQ.impure(other, :queue.from_list([k]))
        end
    end
  end
end
