defmodule Exn.Failure do
  defstruct []
end

defmodule Exn do
  @enforce_keys [
    :failure,
  ]
  defstruct @enforce_keys 

  use Eff

  def failure, do: &failure/2

  def failure(ccons(m, h, t, sub_ctx), x) do
    case h do
      %Exn{failure: op} -> op |> Op.runOp(m, t.(sub_ctx), x)
      _ -> failure(sub_ctx, x)
    end
  end

  def toMaybe(action) do
    handler = %Exn{failure: operation(fn {}, _ -> pure(Nothing) end)}
    handlerRet(&{Just, &1}, handler, action)
  end

  def exceptDefault(default, action) do
    handler(%Exn{failure: operation(fn {}, _ -> pure(default) end)}, action)
  end
end

defimpl Context, for: Exn.Failure do
  def appropriate?(_, %Exn{}), do: true
  def appropriate?(_, _), do: false

  def selectOp(_, %Exn{failure: op}), do: op
end
