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

  def ask(ccons(m, h, t, sub_ctx), input) do
    case h do
      %Reader{ask: op} -> op |> Op.runOp(m, t.(sub_ctx), input)
      _ -> ask(sub_ctx, input)
    end
  end

  def reader(env, action) do
    handler(%Reader{ask: value(env)}, action)
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
