defmodule Exn.Failure do
  defstruct []
end

defmodule Exn do
  @enforce_keys [
    :failure,
  ]
  defstruct @enforce_keys 

  import Eff

  def failure, do: %Exn.Failure{}

  def toMaybe(action) do
    handler = %Exn{failure: operation(fn {}, _ -> pure(Nothing) end)}
    handlerRet(&{Just, &1}, handler, action)
  end

  def exceptDefault(x, action) do
    handler(%Exn{failure: operation(fn {}, _ -> pure(x) end)}, action)
  end
end

defimpl Context, for: Exn.Failure do
  def appropriate?(_, %Exn{}), do: true
  def appropriate?(_, _), do: false

  def selectOp(_, %Exn{failure: op}), do: op
end
