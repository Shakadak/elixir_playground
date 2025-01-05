defmodule The do
  @enforce_keys [
    :type,
    :value,
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  defmacro the(type, value) do
    quote do
      %unquote(__MODULE__){
        type: unquote(type),
        value: unquote(value),
      }
    end
  end
end
