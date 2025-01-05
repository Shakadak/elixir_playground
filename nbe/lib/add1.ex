defmodule Add1 do
  @enforce_keys [
    :pred
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    pred: Nbe.value,
  }

  defmacro add1(pred) do
    quote do
      %unquote(__MODULE__){
        pred: unquote(pred),
      }
    end
  end
end
