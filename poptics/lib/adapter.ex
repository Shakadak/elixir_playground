defmodule Adapter do
  import Type

  record adapter(a, b, s, t) = adapter %{from: (s -> a), to: (b -> t)}

  def flatten do
    from = fn {{x, y}, z} -> {x, y, z} end
    to = fn {x, y, z} -> {{x, y}, z} end

    adapter(from, to)
  end

  require Profunctor

  def adapterC2P(adapter(o, i), profunctor), do: &Profunctor.dimap(o, i, &1, profunctor)

  def adapterP2C(l), do: l.(Adapter).(adapter(&Function.identity/1, &Function.identity/1))
end

defmodule Profunctor.Adapter do
  import Adapter

  def dimap(f, g, adapter(o, i)), do: adapter(&o.(f.(&1)), &g.(i.(&1)))
end
