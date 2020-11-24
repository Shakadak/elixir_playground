defmodule ArrowChoice do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    arrow: Arrow.t,
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    arrow: Arrow.__struct__(),
    left: fn _ -> raise("ArrowChoice : missing definition for left") end,
    right: fn _ -> raise("ArrowChoice : missing definition for right") end,
    multiplex: fn _ -> raise("ArrowChoice : missing definition for multiplex") end,
    merge: fn _ -> raise("ArrowChoice : missing definition for merge") end,
  }

  def __struct__(kv) do
    required_keys = [
      :arrow,
      :left,
      :right,
      :multiplex,
      :merge,
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

    arrow = Map.fetch!(base_dict, :arrow)

    {left, multiplex} = case base_dict do
      %{left: left} ->
        multiplex = Map.get(base_dict, :multiplex, fn arl, arr ->
          c = arrow.category
          mirror = arrow.arr.(fn
            {:Left, l} -> {:Right, l}
            {:Right, r} -> {:Left, r}
          end)
          left.(arl) |> c.>>>.(mirror) |> c.>>>.(left.(arr)) |> c.>>>.(mirror)
        end)
        {left, multiplex}

      %{multiplex: multiplex} ->
        left = Map.get(base_dict, :left, fn ar -> multiplex.(ar, arrow.category.id) end)
        {left, multiplex}

      _ ->
        raise("ArrowChoice minimal definition require either `left` or `multiplex`")
    end

    right = Map.get(base_dict, :right, fn ar -> multiplex.(arrow.category.id, ar) end)

    merge = Map.get(base_dict, :merge, fn arl, arr ->
      c = arrow.category
      untag = arrow.arr.(fn
        {:Left , l} -> l
        {:Right, r} -> r
      end)
      multiplex.(arl, arr) |> c.>>>.(untag)
    end)


    %__MODULE__{
      arrow: arrow,
      left: left,
      right: right,
      multiplex: multiplex,
      merge: merge,
    }
  end
end
