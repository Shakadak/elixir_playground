defmodule Poptics do
end

defmodule UpStar do
  import Type
  record up_star(f, a, b) = up_star %{un_up_star: (a -> f(b))}
end

defmodule Profunctor.UpStar do
  import UpStar

  def mk(functor) do
    %{dimap: &dimap(&1, &2, &3, functor)}
  end

  def dimap(up_star(h), f, g, functor) do
    require Functor
    h_ = &Functor.map(h, &1, functor)
    go = Profunctor.Function.dimap(f, g, h_)
    up_star(go)
  end
end

defmodule Cartesian.UpStar do
  import UpStar

  require Functor

  def mk(functor) do
    %{
      first: &first(&1, functor),
      second: &second(&1, functor),
    }
  end

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}
  def rstrength({fx, y}, functor), do: Functor.map(fn x -> {x, y} end, fx, functor)
  def lstrength({x, fy}, functor), do: Functor.map(fn y -> {x, y} end, fy, functor)

  def compose(f, g, x), do: f.(g.(x))

  def first(up_star(un_up_star), functor) do
    id = &Function.identity/1
    f = &cross(un_up_star, id, &1)
    rstrength = &rstrength(&1, functor)
    go = &compose(rstrength, f, &1)
    up_star(go)
  end

  def second(up_star(un_up_star), functor) do
    id = &Function.identity/1
    f = &cross(id, un_up_star, &1)
    lstrength = &lstrength(&1, functor)
    go = &compose(lstrength, f, &1)
    up_star(go)
  end
end

defmodule Cocartesian.UpStar do
  import UpStar

  require Applicative
  require Functor
  require Either

  def mk(applicative) do
    %{
      left: &left(&1, applicative),
      right: &right(&1, applicative),
    }
  end

  def left(up_star(unUpStar), applicative) do
    functor = Applicative.superclass(applicative)
    pure = &Applicative.pure(&1, applicative)
    left = &Either.left(&1)
    right = &Either.right(&1)
    l_ = &Functor.map(left, &1, functor)
    on_left = &compose(l_, unUpStar, &1)
    on_right = &compose(pure, right, &1)
    up_star(&Either.either(on_left, on_right, &1))
  end

  def right(up_star(unUpStar), applicative) do
    functor = Applicative.superclass(applicative)
    left = &Either.left(&1)
    right = &Either.right(&1)
    r_ = &Functor.map(right, &1, functor)
    pure = &Applicative.pure(&1, applicative)
    on_left = &compose(pure, left, &1)
    on_right = &compose(r_, unUpStar, &1)
    up_star(&Either.either(on_left, on_right, &1))
  end

  def compose(f, g, x), do: f.(g.(x))
end
