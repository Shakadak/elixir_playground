defmodule Zero do
  @enforce_keys []
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  defmacro zero do
    quote do
      %unquote(__MODULE__){
      }
    end
  end
end
