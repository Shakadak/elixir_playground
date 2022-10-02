defmodule Prism do
  import Type

  record prism(a, b, s, t) = prism %{match: (s -> either(t, a)), build: (b -> t)}

  import Either

  def the do
    match = fn
      {:Just, x} -> right(x)
      :Nothing -> left(:Nothing)
    end
    build = fn x -> {:Just, x} end

    prism(match, build)
  end

  def whole do
    proper_fraction = fn x ->
      :erlang.float_to_binary(x, [:compact, decimals: 20])
      |> String.split(".", parts: 2)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end
    match = fn x ->
      case proper_fraction.(x) do
        {n, 0} -> right(n)
        _ -> left(x)
      end
    end
    build = &:erlang.float/1

    prism(match, build)
  end

  def prismC2P(prism(m, b), cocartesian) do
    require Cocartesian
    require Profunctor

    profunctor = Cocartesian.superclass(cocartesian)
    id = &Bag.id/1
    g = &either(id, b, &1)
    &Profunctor.dimap(m, g, Either.right(&1), profunctor)
  end

  def prismP2C(l), do: l.(prism(&Either.right/1, &Bag.id/1))
end

defmodule Profunctor.Prism do
  import Prism

  def dimap(f, g, prism(m, b)) do
    id = &Bag.id/1
    match = &Either.plus(g, id).(m.(f.(&1)))
    build = &g.(b.(&1))
    prism(match, build)
  end
end

defmodule Cocartesian.Prism do
  import Prism

  require Either
  require Cocartesian

  Cocartesian.defaults(Cocartesian.Profunctor)

  def left (prism m, b) do
    id = &Bag.id/1
    left = &Either.left/1

    on_left = &Either.plus(left, id).(m.(&1))
    on_right = &left(right(&1))

    match = &Either.either(on_left, on_right, &1)
    build = &Either.left(b.(&1))

    prism match, build
  end

  def right (prism m, b) do
    id = &Bag.id/1
    right = &Either.right/1

    on_left = &left(left(&1))
    on_right = &Either.plus(right, id).(m.(&1))

    match = &Either.either(on_left, on_right, &1)
    build = &Either.right(b.(&1))

    prism match, build
  end
end
