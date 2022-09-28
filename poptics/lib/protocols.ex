defprotocol Functor do
  @doc "map : f a -> (a -> b) -> f b"
  def map(t, f)
end

defprotocol Applicative do
  @doc "pure : a -> f a"
  def pure(x)

  @doc "ap : f (a -> b) -> f a -> f b"
  def ap(f, x)
end

defprotocol Profunctor do
  @doc "dimap : p a b -> (a -> a') -> (b -> b') -> p a' b'"
  def dimap(x, f, g)
end

defprotocol Cartesian do
  @doc "first : p a b -> p {a, c} {b, c}"
  def first(x)
  @doc "first : p a b -> p {c, a} {c, b}"
  def second(x)
end

defprotocol Cocartesian do
  @doc "left : p a b -> p (a + c) (b + c)"
  def left(x)
  @doc "right : p a b -> p (c + a) (c + b)"
  def right(x)
end

defimpl Profunctor, for: Function do
  def dimap(h, f, g) do
    fn x -> g.(h.(f.(x))) end
  end
end

defimpl Cartesian, for: Function do
  import Curry

  def cross(f, g, {x, y}), do: {f.(x), g.(y)}

  def first(h), do: curry(cross/3).(h, &Function.identity/1)
  def second(h), do: curry(cross/3).(&Function.identity/1, h)
end

defimpl Cocartesian, for: Function do
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
