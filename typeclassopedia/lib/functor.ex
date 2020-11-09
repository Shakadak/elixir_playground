defmodule Functor do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # mandatory
  * `flmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, optional
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    map: ((any -> any), any -> any),
    flmap: (any, (any -> any) -> any),
    lift_left: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    map: fn _, _ -> raise("Functor: missing definition for fmap") end,
    flmap: fn _, _ -> raise("Functor: missing definition for flmap") end,
    lift_left: fn _, _ -> raise("Functor: missing definition for lift_left") end,
  }

  def __struct__(kv) do
    {map, keys} =
      Enum.reduce(kv, {__struct__(), [:map, :flmap, :lift_left]}, fn {key, val}, {map, keys} ->
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
    map = Map.fetch!(t, :map)
    flmap = Map.get(t, :flmap, fn mx, f -> map.(f, mx) end)

    lift_left = Access.get(t, :lift_left, fn a, mb -> map.(fn _ -> a end, mb) end)

    %__MODULE__{map: map, flmap: flmap, lift_left: lift_left}
  end
end
