defmodule Bifunctor do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : (a -> b) -> f a -> f b

  * `map`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    bimap: (any, (any -> any) -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    bimap: fn _, _ -> raise("Functor: missing definition for fmap") end,
    first: fn _, _ -> raise("Functor: missing definition for lift_left") end,
    second: fn _, _ -> raise("Functor: missing definition for lift_left") end,
  }

  def __struct__(kv) do
    {map, keys} =
      Enum.reduce(kv, {__struct__(), [:bimap, :first, :second]}, fn {key, val}, {map, keys} ->
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

    {bimap, first, second} = case base_dict do
      %{bimap: bimap} ->
        first =  Map.get(base_dict, :first,  fn x, f -> bimap.(x, f, fn x -> x end) end)
        second = Map.get(base_dict, :second, fn x, g -> bimap.(x, fn x -> x end, g) end)
        {bimap, first, second}

      %{first: first, second: second} ->
        bimap = Map.get(base_dict, :bimap, fn x, f, g -> x |> first.(f) |> second.(g) end)
        {bimap, first, second}

      _ ->
        raise("Bifunctor minimal definition require either `bimap`, or both `first` and `second`")
    end

    %__MODULE__{bimap: bimap, first: first, second: second}
  end
end
