defmodule Test.Basic do
  use TypedAttempt

  type now, -: (-> io(time()))
  foreign import Kernel.+, -: (int(), int() -> int())

  type sub, -: (int(), int() -> int())
  unsafe deft sub(x, y), do: x - y

  type add, -: (int(), int() -> int())
  deft add(x, y),
    do: x + y

  type plus1, -: (int() -> int())
  deft plus1(x) do
    x + 1
  end

  type add3, -: (int(), int(), int() -> int())
  deft add3(x, y, z),
    do: x + y + z

  type add_plus1, -: (int(), int() -> int())
  deft add_plus1(x, y) do
    z = add(x, y)
    plus1(z)
  end

  type one, -: (() -> int())
  deft one, do: 1

  type sum, -: (list(int()) -> int())
  deft sum([]), do: 0
  deft sum([x | xs]), do: x + sum(xs)

  type len, V: [a], -: (list(a) -> int())
  deft len([]), do: 0
  deft len([_ | xs]), do: 1 + len(xs)

  type map, V: [src, tgt], -: ((src -> tgt), list(src) -> list(tgt))
  deft map(_, []), do: []
  deft map(f, [x | xs]), do: [f.(x) | map(f, xs)]

  type plus1s, -: (list(int()) -> list(int()))
  deft plus1s(xs), do: map(&plus1/1, xs)

  type id, V: [a], -: (a -> a)
  deft id(x), do: x

  type const, V: [a, b], -: (a, b -> a)
  deft const(x, _), do: x

  type byte_size, -: (binary() -> int())

  type len_b, V: [a], -: ((list(a) | binary()) -> int())
  #type len_b, V: [a], -: (int() | binary() -> int())
  deft len_b(xs) when is_list(xs), do: len(xs)
  deft len_b(bin) when is_binary(bin), do: byte_size(bin)

  type fst, V: [a, b], -: (tuple(a, b) -> a)
  type snd, V: [a, b], -: (tuple(a, b) -> b)

  deft fst({x, _}), do: x
  deft snd({_, y}), do: y

  type tuple, V: [l, r], -: (l, r -> tuple(l, r))
  deft tuple(a, b), do: {a, b}

  type swap, V: [l, r], -: (tuple(l, r) -> tuple(r, l))
  deft swap({x, y}), do: {y, x}

  type banana, -: (binary() -> int())
  deft banana(x)
  when x == 1
  when x == 2
  when x == 3 do
    0
  end

  # type banana :: forall(f, a, b), where(functor(f), num(a), num(b)), =: ((a -> b) -> (f(a) -> f(b)))
  # type banana, V: [f, a, b], =: functor(f), =: num(a), =: num(b), -: ((a -> b) -> (f(a) -> f(b)))
  # type banana, V: [f, a, b], C: [functor(f), num(a), num(b)], -: ((a -> b) -> (f(a) -> f(b)))
  # type banana, V: [f, a, b], C: [functor(f)], -: ((a -> b) -> (f(a) -> f(b)))
  # type banana, V: [f, a, b], -: ((a -> b) -> (f(a) -> f(b)))
  # type banana, V: [f, a, b], C: [functor(f), num(a), num(b)], -: ((a -> b), f(a) -> f(b))
  # type list_map, V: [a, b], -: ((a -> b), list(a) -> list(b))
  # type banana :: ~T/forall f a b. Functor f => (a -> b) -> f a -> f b/
end
