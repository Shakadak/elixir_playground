defmodule Local.List do
  defmacro map(m, f), do: (quote do Enum.map(unquote(m), unquote(f)) end)

  defmacro pure(x), do: (quote do [unquote(x)] end)

  defmacro bind(m, f), do: (quote do Enum.flat_map(unquote(m), unquote(f)) end)

  defmacro mzero, do: (quote do [] end)

  defmacro mplus(l, r), do: (quote do unquote(l) ++ unquote(r) end)
end
