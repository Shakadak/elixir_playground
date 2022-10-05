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

  def prismC2P(prism(m, b), type) do
    require Cocartesian
    require Profunctor

    id = &Bag.id/1
    g = &either(id, b, &1)
    &Profunctor.dimap(m, g, Cocartesian.right(&1, type), type)
  end

  def prismP2C(l), do: l.(prism(&Either.right/1, &Bag.id/1))

  def theP(type), do: prismC2P(the(), type)

  def theP_(type) do
    require Cocartesian
    require Profunctor
    require Either

    id = &Bag.id/1
    right = &Either.right/1
    just = &{:Just, &1}
    f = &Bag.maybe(Either.left(:Nothing), right, &1)
    g = &either(id, just, &1)
    &Profunctor.dimap(f, g, Cocartesian.right(&1, type), type)
  end

  def withPrism(p, f) do
    import Market
    require Either

    case p.(Market).(market(&Bag.id/1, &Either.right/1)) do
      market(g, h) -> f.(g, h)
    end
  end

  def matching(p, s) do
    withPrism(p, fn _, f -> f.(s) end)
  end

  def review(p, b) do
    import Tagged
    case p.(Tagged).(tagged(b)) do
      tagged(x) -> x
    end
  end
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
