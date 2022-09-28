defmodule Poptics do
end

defmodule UpStar do
  import Type
  record up_star(f, a, b) = up_star %{un_up_star: (a -> f(b))}
end

defimpl Profunctor, for: UpStar do
  import UpStar
  def dimap(up_star(h), f, g), do: up_star(fn x -> Functor.map(x, Profunctor.dimap(h, f, g)) end)
end

defimpl Cartesian, for: UpStar do
  import UpStar
  import Curry

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}
  def rstrength({fx, y}), do: Functor.map(fx, fn x -> {x, y} end)
  def lstrength({x, fy}), do: Functor.map(fy, fn y -> {x, y} end)

  def compose(f, g, x), do: f.(g.(x))

  def first(up_star(un_up_star)), do: up_star(curry(compose/3).(&rstrength/1).(curry(cross/3).(un_up_star).(&Function.identity/1)))
  def second(up_star(un_up_star)), do: up_star(curry(compose/3).(&lstrength/1).(curry(cross/3).(&Function.identity/1).(un_up_star)))
end
