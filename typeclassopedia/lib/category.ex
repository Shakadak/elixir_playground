defmodule Category do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    id: any,
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    id: fn -> raise("Category: missing definition for fmap") end,
    ..: fn _, _ -> raise("Category: missing definition for lift_left") end,
    <<<: fn _, _ -> raise("Category: missing definition for <<<") end,
    >>>: fn _, _ -> raise("Category: missing definition for <<<") end,
  }

  def __struct__(kv) do
    {map, keys} =
      Enum.reduce(kv, {__struct__(), [:id, :.., :<<<, :>>>]}, fn {key, val}, {map, keys} ->
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

    id = Map.fetch!(base_dict, :id)
    compose = Map.fetch!(base_dict, :..)
    compose_rtl = Map.get(base_dict, :<<<, compose)
    compose_ltr = Map.get(base_dict, :>>>, fn f, g -> compose.(g, f) end)

    %__MODULE__{id: id, ..: compose, <<<: compose_rtl, >>>: compose_ltr}
  end

  # Prelude Control.Category> t1 = (+1) <<< (*2)
  # Prelude Control.Category> t1 2
  # 5
  # Prelude Control.Category> t2 = (+1) >>> (*2)
  # Prelude Control.Category> t2 2
  # 6
  # Prelude Control.Category> t1 = (+1) <<< (*2) <<< negate
  # Prelude Control.Category> t1 = (+1) <<< (*2)
  # Prelude Control.Category> t12 = (+1) <<< (*2) <<< negate
  # Prelude Control.Category> t12 2
  # -3
  # Prelude Control.Category> t22 = (+1) >>> (*2) >>> negate
  # Prelude Control.Category> t22 2
  # -6

  @doc """
      t1 = fn x -> x + 1 end <<< fn x -> x * 2 end
      t1.(2)
      
      t2 = fn x -> x + 1 end >>> fn x -> x * 2 end
      t2.(2)
      
      t12 = fn x -> x + 1 end <<< fn x -> x * 2 end <<< fn x -> -x end
      t12.(2)
      
      t22 = fn x -> x + 1 end >>> fn x -> x * 2 end >>> fn x -> -x end
      t22.(2)
      
  """
  def dummy, do: nil
end
