defmodule Bag do
  def id(x), do: x

  def const(a, _b), do: a

  def fst({x, _}), do: x

  def snd({_, y}), do: y

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}

  def fork(f, g, x), do: {f.(x), g.(x)}

  def pair(h, k, {x, y}, applicative) do
    require Applicative
    Applicative.liftA2(&{&1, &2}, h.(x), k.(y), applicative)
  end
end
