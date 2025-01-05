defmodule N.Rec do
  @enforce_keys [
    :type,
    :target,
    :base,
    :step,
  ]
  defstruct @enforce_keys

  defmacro n_rec(type, target, base, step) do
    quote do
      %unquote(__MODULE__){
        type: unquote(type),
        target: unquote(target),
        base: unquote(base),
        step: unquote(step),
      }
    end
  end
end
