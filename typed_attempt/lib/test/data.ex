defmodule Test.Data do
  use TypedAttempt

  data bool() do
    type t, -: (-> bool())
    type f, -: (-> bool())
  end

  data wrap(a), do: type wrap, -: (a -> wrap(a))

  data option(a) do
    type none, -: (-> option(a))
    type some, -: (a -> option(a))
  end

  data either(a, b) do
    type left, -: (a -> either(a, b))
    type right, -: (b -> either(a, b))
  end

  type option, V: [src, tgt], -: (tgt, (src -> tgt), option(src) -> tgt)
  deft option(default, _, none()), do: default
  deft option(_, f, some(x)), do: f.(x)

  #type either, V: [l, r, tgt], -: ((l -> tgt), (r -> tgt), either(l, r) -> tgt)
  #deft either(on_l, _, left(x)), do: left(on_l.(x))
  #deft either(_, on_r, right(x)), do: on_r.(x)

  #newtype additive(a), do: type mkAdditive, -: (a -> additive(a))

  #newtype state(s, a),
  #  do: type state, -: ((s -> tuple(s, a)) -> state(s, a))

  #newtype forget(r, a, b), do: type forget, -: ((a -> r) -> forget(r, a, b))

  #newtype forget(r, a, b) do
  #  type forget, -: ((a -> r) -> forget(r, a, b))
  #end

  #type_syn optic(p, s, t, a, b), -: (p(a, b) -> p(s, t))

  #type_syn lens(s, t, a, b), V: [p], C: [strong(p)], -: optic(p, s, t, a, b)
end
