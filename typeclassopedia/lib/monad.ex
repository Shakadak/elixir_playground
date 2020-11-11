defmodule Monad do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    applicative: Applicative.t,
    bind: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    applicative: Applicative.__struct__,
    bind: fn _, _ -> raise("Monad: missing definition for bind") end,
    rightM: fn _, _ -> raise("Monad: missing definition for rightM") end,
    return: fn _ -> raise("Monad: missing definition for return") end,
  }

  def __struct__(kv) do
    required_keys = [:applicative, :bind, :return, :rightM]
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
    applicative = Map.fetch!(t, :applicative)
    bind = Map.fetch!(t, :bind)
    return = Map.get(t, :return, applicative.pure)
    rightM = Map.get(t, :rightM, fn l, r -> bind.(l, fn _ -> r end) end)


    %__MODULE__{
      applicative: applicative,
      bind: bind,
      return: return,
      rightM: rightM,
    }
  end

  def join(mma, dict), do: dict.bind.(mma, fn x -> x end)

end
