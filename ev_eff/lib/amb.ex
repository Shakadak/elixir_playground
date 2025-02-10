defmodule Amb.Op do
  @enforce_keys [:op]
  defstruct @enforce_keys
end

defmodule Amb do
  @enforce_keys [:flip]
  defstruct @enforce_keys

  use Eff

  def flip, do: %Amb.Op{op: :flip}

  def allResults(action) do
    handler = %Amb{
      flip: operation(fn {}, k ->
        m Eff do
          xs <- k.(true)
          #_ = IO.inspect(xs, label: "allResult, branch true")
          ys <- k.(false)
          #_ = IO.inspect(ys, label: "allResult, branch false")
          pure(xs ++ ys)
        end
      end)
    }
    handlerRet(fn x -> [x] end, handler, action)
  end

  def firstResult(action) do
    handler = %Amb{
      flip: operation(fn {}, k ->
        m Eff do
          xs <- k.(true)
          case xs do
            {Just, _} -> pure(xs)
            Nothing -> k.(false)
          end
        end
      end)
    }
    handler(handler, action)
  end
end

defimpl Context, for: Amb.Op do
  def appropriate?(_, %Amb{}), do: true
  def appropriate?(_, _), do: false

  def selectOp(_, %Amb{flip: op}) do op end
end
