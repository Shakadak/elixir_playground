defmodule Stop do
  @enforce_keys [
    :expr,
    :message,
  ]
  defstruct @enforce_keys

  defmacro stop(expr, message) do
    quote do
      %unquote(__MODULE__){
        expr: unquote(expr),
        message: unquote(message),
      }
    end
  end

  @type t :: %__MODULE__{
    expr: Nbe.expression,
    message: String.t,
  }
end
