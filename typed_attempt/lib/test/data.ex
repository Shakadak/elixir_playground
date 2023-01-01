defmodule Test.Data do
  import TypeDeclaration

  data bool() do
    type t, -: bool()
    type f, -: bool()
  end

  data wrap(a), do: type wrap, -: (a -> wrap(a))

  data option(a) do
    type none, -: option(a)
    type some, -: (a -> option(a))
  end

  newtype additive(a), do: type mkAdditive, -: (a -> additive(a))

  newtype state(s, a),
    do: type state, -: ((s -> tuple(s, a)) -> state(s, a))

  newtype forget(r, a, b), do: type forget, -: ((a -> r) -> forget(r, a, b))

  newtype forget(r, a, b) do
    type forget, -: ((a -> r) -> forget(r, a, b))
  end

  type_syn optic(p, s, t, a, b), -: (p(a, b) -> p(s, t))

  type_syn lens(s, t, a, b), V: [p], C: [strong(p)], -: optic(p, s, t, a, b)
end
