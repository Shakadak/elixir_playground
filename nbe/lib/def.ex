defmodule Def do
  @enforce_keys [
    :type,
    :value,
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    type: Nbe.type,
    value: Nbe.value,
  }

  defmacro def!(type, value) do
    quote do
      %unquote(__MODULE__){
        type: unquote(type),
        value: unquote(value),
      }
    end
  end
end
