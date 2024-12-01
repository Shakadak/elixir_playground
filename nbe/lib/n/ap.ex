defmodule N.Ap do
  @enforce_keys [
    :rator,
    :rand,
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    rator: Nbe.neutral,
    rand: Nbe.value,
  }

  defmacro n_ap(rator, rand) do
    quote do
      %unquote(__MODULE__){
        rator: unquote(rator),
        rand: unquote(rand),
      }
    end
  end
end
