defmodule DataTypes do

  defmacro unknown do quote(do: :_?) end
  defmacro fun(params, return) do quote(do: {:fun, unquote(params), unquote(return)}) end
  defmacro hkt(name, params) do quote(do: {:hkt, unquote(name), unquote(params)}) end
  defmacro alt(types) do quote(do: {:alt, unquote(types)}) end
  defmacro type(name) do quote(do: {:type, unquote(name)}) end
  defmacro variable(name) do quote(do: {:"$variable", unquote(name)}) end
  defmacro rigid_variable(name) do quote(do: {:"$rigid_variable", unquote(name)}) end
end
