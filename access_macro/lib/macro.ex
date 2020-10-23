defmodule MyMacro do
  defmacro macro(x, xs, ys) do
    IO.inspect(x)
    IO.inspect(xs)
    IO.inspect(ys)
    quote do :ok end
  end
end
