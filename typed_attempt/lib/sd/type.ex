defmodule Type do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro tvar(x), do: quote(do: %unquote(__MODULE__){@: {:tvar, unquote(x)}})
  defmacro tcon(x), do: quote(do: %unquote(__MODULE__){@: {:tcon, unquote(x)}})
  defmacro tarr(t1, t2), do: quote(do: %unquote(__MODULE__){@: {:tarr, {unquote(t1), unquote(t2)}}})

  def typeInt, do: tcon("Int")
  def typeBool, do: tcon("Bool")
end

defimpl Inspect, for: Type do
  import Type
  import Inspect.Algebra

  def inspect(tvar(x), opts), do: to_doc(x, opts)
  def inspect(tcon(x), _opts), do: x
  def inspect(tarr(t1, t2), opts), do: concat([to_doc(t1, opts), " -> ", to_doc(t2, opts)])
end
