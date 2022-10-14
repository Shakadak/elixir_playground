defmodule UpStar do
  import Type
  record up_star(f, a, b) = up_star %{unUpStar: (a -> f(b))}
end

defmodule Profunctor.UpStar do
  import UpStar

  def mk(functor) do
    %{Profunctor => %{dimap: &dimap(&1, &2, &3, functor)}}
  end

  def dimap(f, g, up_star(h), functor) do
    require Functor
    g_ = &Functor.map(g, &1, functor)
    go = Profunctor.Function.dimap(f, g_, h)
    up_star(go)
  end
end

defmodule Cartesian.UpStar do
  import UpStar

  require Functor

  def mk(type) do
    profunctor = Profunctor.UpStar.mk(type)
    cartesian = %{
      Cartesian => %{
        first: &first(&1, type),
        second: &second(&1, type),
      },
    }
    Map.merge(profunctor, cartesian)
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

  def mk(type) do
    profunctor = Profunctor.UpStar.mk(type)
    cocartesian = %{
      Cocartesian => %{
        left: &left(&1, type),
        right: &right(&1, type),
      },
    }
    Map.merge(profunctor, cocartesian)
  end

  def left(up_star(unUpStar), type) do
    pure = &Applicative.pure(&1, type)
    left = &Either.left(&1)
    right = &Either.right(&1)
    l_ = &Functor.map(left, &1, type)
    on_left = &compose(l_, unUpStar, &1)
    on_right = &compose(pure, right, &1)
    up_star(&Either.either(on_left, on_right, &1))
  end

  def right(up_star(unUpStar), type) do
    on_left = &Applicative.pure(Either.left(&1), type)
    on_right = fn x -> Functor.map(&Either.right(&1), unUpStar.(x), type) end
    up_star(&Either.either(on_left, on_right, &1))
  end

  def compose(f, g, x), do: f.(g.(x))
end

defmodule Monoidal.UpStar do
  import UpStar

  require Applicative

  def mk(type) do
    profunctor = Profunctor.UpStar.mk(type)
    monoidal = %{
      Monoidal => %{
        empty: fn -> empty(type) end,
        par: &par(&1, &2, type),
      },
    }
    Map.merge(profunctor, monoidal)
  end

  def empty(type), do: up_star(&Applicative.pure(&1, type))

  def par(h, k, type), do: up_star(&Bag.pair(h.unUpStar, k.unUpStar, &1, type))
end
