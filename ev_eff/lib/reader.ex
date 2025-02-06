defmodule Reader do
  @enforce_keys [
    :ask,
  ]
  defstruct @enforce_keys 

  import Eff

  def ask, do: fn {} -> {:banana} end

  def reader(action) do
    handler(%Reader{ask: value("world")}, action)
  end

  def r2 do
    %Reader{ask: function(fn {} -> pure("world") end)}
  end

  def r3 do
    %Reader{ask: operation(fn {}, k -> k.("world") end)}
  end
end
