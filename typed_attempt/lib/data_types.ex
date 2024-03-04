defmodule DataTypes do

  defmacro unknown do quote(do: :_?) end
  defmacro fun(params, return) do quote(do: {:fun, unquote(params), unquote(return)}) end
  defmacro hkt(name, params) do quote(do: {:hkt, unquote(name), unquote(params)}) end
  defmacro type(name) do quote(do: {:type, unquote(name)}) end
  defmacro variable(name) do quote(do: {:"$variable", unquote(name)}) end
  defmacro rigid_variable(name) do quote(do: {:"$rigid_variable", unquote(name)}) end

  def map_variable(type, f) do
    case type do
      variable(name) -> f.(name)
      type -> apply_type(type, &map_variable(&1, f))
    end
  end

  def map_name(type, f) do
    case type do
      type(name) -> type(f.(name))
      rigid_variable(name) -> rigid_variable(f.(name))
      variable(name) -> variable(f.(name))
      hkt(name, params) ->
        hkt(f.(name), Enum.map(params, &map_name(&1, f)))
      fun(params, return) ->
        params = Enum.map(params, &map_name(&1, f))
        fun(params, map_name(return, f))
    end
  end

  def apply_type(type, f) do
    case type do
      hkt(name, params) ->
        hkt(name, Enum.map(params, f))
      fun(params, return) ->
        params = Enum.map(params, f)
        fun(params, f.(return))
      type -> type
    end
  end
end
