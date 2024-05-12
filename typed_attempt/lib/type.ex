defmodule Type do
  defmacro unknown do quote(do: :_?) end
  defmacro type(name) do quote(do: {:type, unquote(name)}) end
  defmacro variable(name) do quote(do: {:"$variable", unquote(name)}) end
  defmacro rigid_variable(name) do quote(do: {:"$rigid_variable", unquote(name)}) end
end

defmodule TypeF do
  defmacro hkt(name, params) do quote(do: {:hkt, unquote(name), unquote(params)}) end
  defmacro fun(params, return) do quote(do: {:fun, unquote(params), unquote(return)}) end
end
