defmodule State do
  import Type
  record state(s, a) = state %{run: (s -> {a, s})}

  def inc(b), do: state(fn n -> {b, n + 1} end)

  def countOdd(n) do
    require Integer
    if Integer.is_even(n) do Applicative.State.pure(false) else inc(true) end
  end
end

defmodule Functor.State do
  import State

  def map(f, m), do: state(fn s ->
    {x, s_} = m.run.(s)
    {f.(x), s_}
  end)
end

defmodule Applicative.State do
  import State

  require Applicative

  Applicative.defaults(State)

  def pure(x), do: state(fn s -> {x, s} end)

  def ap(m, n) do
    state(fn s ->
      {f, s_} = m.run.(s)
      {x, s__} = n.run.(s_)
      {f.(x), s__}
    end)
  end
end
