defmodule Exn do
  @enforce_keys [
    :failure,
  ]
  defstruct @enforce_keys 

  import Eff

  def failure, do: fn {} -> {:split} end

  def toMaybe(action) do
    handler = %Exn{failure: operation(fn {}, _ -> pure(Nothing) end)}
    handlerRet(&{Just, &1}, handler, action)
  end

  def exceptDefault(x, action) do
    handler(%Exn{failure: operation(fn {}, _ -> pure(x) end)}, action)
  end
end
