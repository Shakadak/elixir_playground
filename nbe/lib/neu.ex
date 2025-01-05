defmodule Neu do
  @enforce_keys [
    :type,
    :neu,
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    type: Nbe.type,
    neu: Nbe.neutral,
  }

  defmacro neu(type, neu) do
    quote do
      %unquote(__MODULE__){
        type: unquote(type),
        neu: unquote(neu),
      }
    end
  end
end
