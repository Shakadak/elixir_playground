defmodule Functor do
  require Class

  @doc "map : (a -> b) -> f a -> f b"
  Class.mk :map, 2
end

defmodule Applicative do
  require Class

  @doc "map : (a -> b) -> f a -> f b"
  Class.mk :superclass, 0
  Class.mk :pure, 1
  Class.mk :ap, 2
  Class.mk :lift_a2, 3
end

defmodule Profunctor do
  require Class
  @doc "dimap : (a -> a') -> (b -> b') -> p a b -> p a' b'"
  Class.mk :dimap, 3
end

defprotocol Cartesian do
  @doc "first : p a b -> p {a, c} {b, c}"
  def first(x)
  @doc "first : p a b -> p {c, a} {c, b}"
  def second(x)
end

defmodule Cocartesian do
  require Class

  @doc "left : p a b -> p (a + c) (b + c)"
  Class.mk :left, 1
  @doc "right : p a b -> p (c + a) (c + b)"
  Class.mk :right, 1
end

defmodule Profunctor.Function do
  def dimap(f, g, h) do
    fn x -> g.(h.(f.(x))) end
  end
end

defmodule Cartesian.Function do
  import Curry

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}

  def first(h), do: curry(cross/3).(h, &Function.identity/1)
  def second(h), do: curry(cross/3).(&Function.identity/1, h)
end

defmodule Cocartesian.Function do
  def plus(f, g) do
    require Either
    fn
      Either.left(x) -> Either.left(f.(x))
      Either.right(y) -> Either.right(g.(y))
    end
  end

  def left(h), do: plus(h, &Function.identity/1)
  def right(h), do: plus(&Function.identity/1, h)
end
