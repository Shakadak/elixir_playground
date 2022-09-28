defmodule Adapter do
  @enforce_keys [:from, :to]
  defstruct [:from, :to]

  defmacro adapter(from, to) do
    quote do
      %unquote(__MODULE__){from: unquote(from), to: unquote(to)}
    end
  end

  def flatten do
    from = fn {{x, y}, z} -> {x, y, z} end
    to = fn {x, y, z} -> {{x, y}, z} end

    adapter(from, to)
  end
end
