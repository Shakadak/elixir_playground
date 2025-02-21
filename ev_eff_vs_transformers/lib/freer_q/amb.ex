defmodule FreerQ.Amb do
  import FreerQ

  import Bind

  require Workflow.FreerQ

  defmacro __using__([]) do
    quote do
      require FreerQ
      require unquote(__MODULE__)
    end
  end

  defmacro flip, do: quote(do: FreerQ.op(Flip))

  def runAllResults(pure(x)), do: pure([x])
  def runAllResults(impure(op, q)) do
    case op do
      Flip ->
        m Workflow.FreerQ do
          xs <- app(q, true)
          ys <- app(q, false)
          pure(xs ++ ys)
        end
        |> runAllResults()
    end
  end

  def runFirstResult(pure(x)), do: pure(x)
  def runFirstResult({E, op, q}) do
    case op do
      Flip ->
        m Workflow.FreerQ do
          xs <- app(q, true)
          case xs do
            {Just, _} -> pure(xs)
            Nothing -> app(q, false)
          end
        end
        |> runAllResults()
    end
  end
end
