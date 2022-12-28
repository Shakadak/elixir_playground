defmodule Test do
  use TypedAttempt

  typ now :: (-> io(time()))
  foreign import Kernel.+ :: (int(), int() -> int())

  typ sub :: (int(), int() -> int())
  unsafe det sub(x, y), do: x - y

  typ add :: (int(), int() -> int())
  det add(x, y),
    do: x + y

  typ plus1 :: (int() -> int())
  det plus1(x) do
    x + 1
  end

  typ add3 :: (int(), int(), int() -> int())
  det add3(x, y, z),
    do: x + y + z

  typ add_plus1 :: (int(), int() -> int())
  det add_plus1(x, y) do
    z = add(x, y)
    plus1(z)
  end

  typ one :: (() -> int())
  det one, do: 1

  typ sum :: (list(int()) -> int())
  det sum([]), do: 0
  det sum([x | xs]), do: x + sum(xs)

  typ len :: (list(a) -> int())
  det len([]), do: 0
  det len([_ | xs]), do: 1 + len(xs)

  typ map :: ((src -> tgt), list(src) -> list(tgt))
  det map(_, []), do: []
  det map(f, [x | xs]), do: [f.(x) | map(f, xs)]

  typ plus1s :: (list(int()) -> list(int()))
  det plus1s(xs), do: map(&plus1/1, xs)

  typ id :: (a -> a)
  det id(x), do: x

  typ const :: (a, b -> a)
  det const(x, _), do: x

  typ len_b :: ((list(a) | binary()) -> int())
  det len_b(xs) when is_list(xs), do: len(xs)
  det len_b(bin) when is_binary(xs), do: byte_size(xs)

  typ banana :: (binary() -> int())
  det banana(x)
  when x == 1
  when x == 2
  when x == 3 do
    0
  end

  # typ banana :: forall(f, a, b), where(functor(f), num(a), num(b)), =: ((a -> b) -> (f(a) -> f(b)))
  # typ banana, V: [f, a, b], =: functor(f), =: num(a), =: num(b), -: ((a -> b) -> (f(a) -> f(b)))
  # typ banana, V: [f, a, b], C: [functor(f), num(a), num(b)], -: ((a -> b) -> (f(a) -> f(b)))
  # typ banana, V: [f, a, b], C: [functor(f)], -: ((a -> b) -> (f(a) -> f(b)))
  # typ banana, V: [f, a, b], -: ((a -> b) -> (f(a) -> f(b)))
  # typ banana, V: [f, a, b], C: [functor(f), num(a), num(b)], -: ((a -> b), f(a) -> f(b))
  # typ list_map, V: [a, b], -: ((a -> b), list(a) -> list(b))
  # typ banana :: ~T/forall f a b. Functor f => (a -> b) -> f a -> f b/
end
