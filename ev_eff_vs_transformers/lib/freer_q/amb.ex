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

  def allResults(action) do
    handle_relay(action, &pure([&1]), fn
      Flip, k, _ ->
        m Workflow.FreerQ do
          xs <- k.(true)
          ys <- k.(false)
          pure(xs ++ ys)
        end
        _, _, next -> next.()
    end)
  end

  def firstResult(action) do
    handle_relay(action, &pure(&1), fn
      Flip, k, _ ->
        m Workflow.FreerQ do
          xs <- k.(true)
          case xs do
            {Just, _} -> pure(xs)
            Nothing -> k.(false)
          end
        end

      _, _, next -> next.()
    end)
  end
end
