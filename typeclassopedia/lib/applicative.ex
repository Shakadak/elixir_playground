defmodule Applicative do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    functor: Functor.t,
    pure: (any -> any),
    apA: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    functor: Functor.__struct__,
    pure: fn _ -> raise("Applicative: missing definition for pure") end,
    apA: fn _, _ -> raise("Applicative: missing definition for apA") end,
    liftA2: fn _, _ -> raise("Applicative: missing definition for apA") end,
    leftA: fn _, _ -> raise("Applicative: missing definition for leftA") end,
    rightA: fn _, _ -> raise("Applicative: missing definition for leftA") end,
  }

  def __struct__(kv) do
    required_keys = [:functor, :pure, :apA, :liftA2, :leftA, :rightA]
    {map, keys} =
      Enum.reduce(kv, {__struct__(), required_keys}, fn {key, val}, {map, keys} ->
        {Map.replace!(map, key, val), List.delete(keys, key)}
      end)

    case keys do
      [] ->
        map

      _ ->
        raise ArgumentError,
        "the following keys must also be given when building " <>
          "struct #{inspect(__MODULE__)}: #{inspect(keys)}"
    end
  end

  def define(t) do
    t = Map.new(t)
    functor = Map.fetch!(t, :functor)
    pure = Map.fetch!(t, :pure)
    unless Map.has_key?(t, :apA) or Map.has_key?(t, :liftA2) do
      raise KeyError, term: t, key: ":apA, or :liftA2"
    end

    {apA, liftA2} = case t do
      %{apA: apA, liftA2: liftA2} -> {apA, liftA2}
      #%{apA: apA} -> {apA, fn f, mx, my -> apA.(functor.map.(fn x -> fn y -> f.(x, y) end end, mx), my) end}
      #%{apA: apA} -> {apA, fn f, mx, my -> fn x -> fn y -> f.(x, y) end end |> functor.map.(mx) |> apA.(my) end}
      %{apA: apA} -> {apA, fn f, mx, my -> pure.(fn x -> fn y -> f.(x, y) end end) |> apA.(mx) |> apA.(my) end}
      %{liftA2: liftA2} -> {fn mf, mx -> liftA2.(fn f, x -> f.(x) end, mf, mx) end, liftA2}
    end

    leftA =  Map.get(t, :leftA,  fn mx, my -> liftA2.(fn x, _ -> x end, mx, my) end)
    rightA = Map.get(t, :rightA, fn mx, my -> liftA2.(fn _, y -> y end, mx, my) end)

    %__MODULE__{
      functor: functor,
      pure: pure,
      apA: apA,
      liftA2: liftA2,
      leftA: leftA,
      rightA: rightA
    }
  end

  def liftA(f, mx, dict), do: dict.functor.map.(f, mx)

  def liftA3(f, mx, my, mz, dict), do: dict.liftA2.(fn x, y -> fn z -> f.(x, y, z) end end, mx, my) |> dict.apA.(mz)
end
