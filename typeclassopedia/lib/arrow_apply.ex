defmodule ArrowApply do
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
    app: fn _ -> raise("ArrowApply : missing definition for app") end,
  }

  def __struct__(kv) do
    required_keys = [
      :arrow,
      :app,
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
    app = Map.fetch!(base_dict, :app)

    %__MODULE__{
      arrow: arrow,
      app: app,
    }
  end
end
