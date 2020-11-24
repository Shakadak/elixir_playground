defmodule Traversable do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    traverse: (any, (any -> any), any -> any),
    sequence: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    functor: Functor.__struct__(),
    foldable: Foldable.__struct__(),
    traverse: fn _, _, _ -> raise("Traversable: missing definition for traverse") end,
    sequence: fn _, _    -> raise("Traversable: missing definition for sequence") end,
  }

  def __struct__(kv) do
    {map, keys} =
      Enum.reduce(kv, {__struct__(), [:functor, :foldable, :traverse, :sequence]}, fn {key, val}, {map, keys} ->
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

  def define(base_dict) do
    base_dict = Map.new(base_dict)
    functor = Map.fetch!(base_dict, :functor)
    foldable = Map.fetch!(base_dict, :foldable)

    {traverse, sequence} = case base_dict do
      %{traverse: traverse, sequence: sequence} -> {traverse, sequence}
      %{traverse: traverse} ->
        {traverse, fn t, applicative_dict -> traverse.(t, fn x -> x end, applicative_dict) end}

      %{sequence: sequence} ->
        {fn t, f, applicative_dict -> sequence.(functor.fmap.(t, f), applicative_dict) end, sequence}

      %{} -> raise("#{__MODULE__} minimal definition require either traverse or sequence")
    end

    %__MODULE__{
      functor: functor,
      foldable: foldable,
      traverse: traverse,
      sequence: sequence
    }
  end
end
