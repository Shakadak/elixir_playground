defmodule Amb do
  @enforce_keys [:flip]
  defstruct @enforce_keys

  use Eff

  def flip, do: &flip/2

  def flip(ccons(m, h, t, sub_ctx), x) do
    case h do
      %Amb{flip: op} -> op |> Op.runOp(m, t.(sub_ctx), x)
      _ -> flip(sub_ctx, x)
    end
  end

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
