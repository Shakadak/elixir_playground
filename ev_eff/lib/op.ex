defmodule Op do
  @enforce_keys [
    :op,
  ]
  defstruct @enforce_keys

  defmacro op(op) do
    quote do
      %unquote(__MODULE__){
        op: unquote(op),
      }
    end
  end

  defmacro runOp(op, marker, context, x) do
    quote do
      unquote(op).op.(unquote(marker), unquote(context), unquote(x))
    end
  end
end
