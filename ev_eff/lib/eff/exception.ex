defmodule Eff.Exception.Op do
  require Op
  @enforce_keys [:op]
  defstruct @enforce_keys

  def appropriate?(_, %impl{}), do: impl == Eff.Exception

  def runOp(_, %{throw_error: op}, m, ctx, x), do: op |> Op.runOp(m, ctx, x)
end

defmodule Eff.Exception do
  @enforce_keys [
    :throw_error,
  ]
  defstruct @enforce_keys 

  use Eff

  #def throw_error, do: %Eff.Exception.Op{op: :throw_error}
  def throw_error, do: &throw_error/2

  def throw_error(ccons(m, h, t, sub_ctx), x) do
    case h do
      %Eff.Exception{throw_error: op} -> op |> Op.runOp(m, t.(sub_ctx), x)
    end
  end

  def catchError(action, h) do
    handler(%Eff.Exception{throw_error: except(fn x -> h.(x) end)}, action)
  end

  def exceptEither(action) do
    handlerRet(&{Right, &1}, %Eff.Exception{throw_error: except(fn x -> pure({Left, x}) end)}, action)
  end

  def exceptMaybe(action) do
    handler = %Eff.Exception{throw_error: except(fn _ -> pure(Nothing) end)}
    handlerRet(&{Just, &1}, handler, action)
  end

  def exceptDefault(default, action) do
    handler(%Eff.Exception{throw_error: except(fn _ -> pure(default) end)}, action)
  end
end

defimpl Context, for: Eff.Exception.Op do
  def appropriate?(_, %Eff.Exception{}), do: true
  def appropriate?(_, _), do: false

  def selectOp(_, %Eff.Exception{throw_error: op}), do: op
end
