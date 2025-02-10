defmodule Reader.Ask do
  defstruct []
end

defmodule Reader do
  @enforce_keys [
    :ask,
  ]
  defstruct @enforce_keys 

  use Eff

  def ask, do: %Reader.Ask{}

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

defimpl Context, for: Reader.Ask do
  def appropriate?(_, %Reader{}), do: true
  def appropriate?(_, _), do: false

  def selectOp(_, %Reader{ask: op}), do: op
end
