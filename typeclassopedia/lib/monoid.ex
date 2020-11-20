defmodule Monoid do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    semigroup: Semigroup.t,
    mconcat: (any, any -> any),
    mempty: any,
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    semigroup: Semigroup.__struct__,
    mempty: {},
    mappend: fn _, _ -> raise("Monoid: missing definition for mappend") end,
    mconcat: fn _ -> raise("Monoid: missing definition for mconcat") end,
  }

  def __struct__(kv) do
    required_keys = [:semigroup, :mempty, :mappend, :mconcat]
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
    semigroup = Map.fetch!(t, :semigroup)
    mempty = Map.fetch!(t, :mempty)
    mappend = Map.get(t, :mappend, semigroup.<>)
    mconcat = Map.get(t, :mconcat, fn xs -> List.foldr(xs, mempty, mappend) end)

    %__MODULE__{
      semigroup: semigroup,
      mempty: mempty,
      mappend: mappend,
      mconcat: mconcat,
    }
  end
end
