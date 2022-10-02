defmodule Poptics do
end

defmodule UpStar do
  import Type
  record up_star(f, a, b) = up_star %{unUpStar: (a -> f(b))}
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
      superclass: fn -> Profunctor.UpStar end,
      first: &first(&1, functor),
      second: &second(&1, functor),
    }
  end

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}
  def rstrength({fx, y}, functor), do: Functor.map(fn x -> {x, y} end, fx, functor)
  def lstrength({x, fy}, functor), do: Functor.map(fn y -> {x, y} end, fy, functor)

  def compose(f, g, x), do: f.(g.(x))

  def first(up_star(unUpStar), functor) do
    id = &Function.identity/1
    f = &cross(unUpStar, id, &1)
    rstrength = &rstrength(&1, functor)
    go = &compose(rstrength, f, &1)
    up_star(go)
  end

  def second(up_star(unUpStar), functor) do
    id = &Function.identity/1
    f = &cross(id, unUpStar, &1)
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
      superclass: fn -> Profunctor.UpStar end,
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
    on_left = &Applicative.pure(Either.left(&1), applicative)
    on_right = fn x -> Functor.map(&Either.right(&1), unUpStar.(x), functor) end
    up_star(&Either.either(on_left, on_right, &1))
  end

  def compose(f, g, x), do: f.(g.(x))
end

defmodule Monoidal.UpStar do
  import UpStar

  require Applicative

  def mk(applicative) do
    %{
      superclass: fn -> Profunctor.UpStar end,
      empty: fn -> empty(applicative) end,
      par: &par(&1, &2, applicative),
    }
  end

  def pair(h, k, {x, y}, applicative) do
    Applicative.liftA2(&{&1, &2}, h.(x), k.(y), applicative)
  end

  def empty(applicative), do: up_star(&Applicative.pure(&1, applicative))

  def par(h, k, applicative), do: up_star(&pair(h.unUpStar, k.unUpStar, &1, applicative))
end
