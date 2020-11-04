defmodule Functor do
  @typedoc """
  Functor dictionary

  * `fmap`: (f a, f a -> f b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    fmap: (any, (any -> any) -> any),
    lift_left: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    fmap: fn _, _ -> raise("Functor: missing definition for fmap") end,
    lift_left: fn _, _ -> raise("Functor: missing definition for lift_left") end,
  }

  def __struct__(kv) do
    {map, keys} =
      Enum.reduce(kv, {__struct__(), [:fmap, :lift_left]}, fn {key, val}, {map, keys} ->
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
    fmap = case Access.fetch(t, :fmap) do
      {:ok, fmap} -> fmap
      :error -> raise KeyError, key: :fmap, term: t
    end

    lift_left = Access.get(t, :lift_left, fn a, f_b -> fmap.(f_b, fn _ -> a end) end)

    %__MODULE__{fmap: fmap, lift_left: lift_left}
  end
end
