defmodule Functor do
  require Class

  @doc "map : (a -> b) -> f a -> f b"
  Class.mk :map, 2
end

defmodule Applicative do
  require Class

  @doc "pure : a -> f a"
  Class.mk :pure, 1
  @doc "ap : f (a -> b) -> f a -> f b"
  Class.mk :ap, 2
  @doc "liftA2 : (a -> b -> c) -> f a -> f b -> f c"
  Class.mk :liftA2, 3

  defmacro defaults(type) do
    quote do
      def ap(f, x), do: liftA2(&Function.identity/1, f, x)
      def liftA2(f, x, y) do
        require Functor
        require Curry
        f_ = Curry.curry(f, 2)
        ap(Functor.map(f_, x, unquote(type)), y)
      end

      defoverridable ap: 2, liftA2: 3
    end
  end
end

defmodule Profunctor do
  require Class
  @doc "dimap : (a' -> a) -> (b -> b') -> p a b -> p a' b'"
  Class.mk :dimap, 3
end

defmodule Cartesian do
  require Class

  @doc "first : p a b -> p {a, c} {b, c}"
  Class.mk :first, 1
  @doc "second : p a b -> p {c, a} {c, b}"
  Class.mk :second, 1
end

defmodule Cocartesian do
  require Class

  @doc "left : p a b -> p (a + c) (b + c)"
  Class.mk :left, 1
  @doc "right : p a b -> p (c + a) (c + b)"
  Class.mk :right, 1
end

defmodule Monoidal do
  require Class

  @doc "par : p a b -> p c d -> p {a, c} {b, d}"
  Class.mk :par, 2

  @doc "empty : p 1 1"
  Class.mk :empty, 0
end
