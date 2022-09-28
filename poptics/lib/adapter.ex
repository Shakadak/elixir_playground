defmodule Adapter do
  import Type

  record adapter(a, b, s, t) = adapter %{from: (s -> a), to: (b -> t)}

  def flatten do
    from = fn {{x, y}, z} -> {x, y, z} end
    to = fn {x, y, z} -> {{x, y}, z} end

    adapter(from, to)
  end
end
