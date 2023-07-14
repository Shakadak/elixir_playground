defmodule Syntax do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro var(x), do: quote(do: %unquote(__MODULE__){@: {:var, unquote(x)}})
  defmacro app(a1, a2), do: quote(do: %unquote(__MODULE__){@: {:app, {unquote(a1), unquote(a2)}}})
  defmacro lam(a1, a2), do: quote(do: %unquote(__MODULE__){@: {:lam, {unquote(a1), unquote(a2)}}})
  defmacro let(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:let, {unquote(a1), unquote(a2), unquote(a3)}}})
  defmacro lit(x), do: quote(do: %unquote(__MODULE__){@: {:lit, unquote(x)}})
  defmacro ifO(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:if, {unquote(a1), unquote(a2), unquote(a3)}}})
  defmacro fix(x), do: quote(do: %unquote(__MODULE__){@: {:fix, unquote(x)}})
  defmacro op(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:op, {unquote(a1), unquote(a2), unquote(a3)}}})

  defmacro lint(x), do: {:lint, x}
  defmacro lbool(x), do: {:lbool, x}
end

defimpl Inspect, for: Syntax do
  import Syntax
  import Inspect.Algebra

  def inspect(var(x), _opts), do: x
  def inspect(app(a1, a2), opts), do: concat([to_doc(a1, opts), "(", to_doc(a2, opts), ")"])
  def inspect(lam(a1, a2), opts), do: concat(["\\", a1, " -> ", to_doc(a2, opts)])
  def inspect(op(a1, a2, a3), opts), do: concat(["(", to_doc(a2, opts), " #{a1} ", to_doc(a3, opts), ")"])
end
