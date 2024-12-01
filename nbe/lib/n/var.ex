defmodule N.Var do
  @enforce_keys [
    :name,
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    name: Nbe.symbol,
  }

  defmacro n_var(name) do
    quote do
      %unquote(__MODULE__){
        name: unquote(name),
      }
    end
  end
end
