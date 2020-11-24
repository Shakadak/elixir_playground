defmodule Arrow do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    arr: (any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    category: Category.__struct__(),
    arr: fn _, _ -> raise("Functor: missing definition for fmap") end,
    first: fn _, _ -> raise("Functor: missing definition for lift_left") end,
    second: fn _, _ -> raise("Functor: missing definition for lift_left") end,
    parallel: fn _, _ -> raise("Functor: missing defn") end,
    fanout: fn _, _ -> raise("Arrow: missing definition for fanout/2") end,
  }

  def __struct__(kv) do
    required_keys = [
      :arr,
      :first,
      :second,
      :parallel,
      :fanout
    ]

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

  def define(base_dict) do
    base_dict = Map.new(base_dict)

    category = Map.fetch!(base_dict, :category)

    {arr, first, parallel} = case base_dict do
      %{arr: arr, first: first} ->
        parallel = Map.get(base_dict, :parallel, fn ar1, ar2 ->
          c = category
          swap = arr.(fn {x, y} -> {y, x} end)
          first.(ar1) |> c.>>>.(swap) |> c.>>>.(first.(ar2)) |> c.>>>.(swap)
        end)
        {arr, first, parallel}

      %{arr: arr, parallel: parallel} ->
        first = Map.get(base_dict, :first, fn ar -> parallel.(ar, category.id) end)
        {arr, first, parallel}

      _ ->
        raise("Bifunctor minimal definition require `arr` and either `first` or `parallel`")
    end

    second = Map.get(base_dict, :second, fn ar -> parallel.(category.id, ar) end)

    fanout = Map.get(base_dict, :fanout, fn ar1, ar2 ->
      c = category
      arr.(fn x -> {x, x} end) |> c.>>>.(parallel.(ar1, ar2))
    end)

    %__MODULE__{
      category: category,
      arr: arr,
      first: first,
      second: second,
      parallel: parallel,
      fanout: fanout
    }
  end
end
