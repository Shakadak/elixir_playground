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
end
