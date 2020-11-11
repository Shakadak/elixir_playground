defmodule Semigroup do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    concat: (any, any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    concat: fn _, _ -> raise("Semigroup: missing definition for concat") end,
    sconcat: fn _ -> raise("Semigroup: missing definition for sconcat") end,
    stimes: fn _, _ -> raise("Semigroup: missing definition for stimes") end,
  }

  def __struct__(kv) do
    required_keys = [:concat, :sconcat, :stimes]
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
    concat = Map.fetch!(t, :concat)
    sconcat = Map.get(t, :sconcat, fn xs -> Enum.reduce(xs, concat) end)
    stimes = Map.get(t, :stimes, fn n, x -> stimes_default(concat, n, x) end)

    %__MODULE__{
      concat: concat,
      sconcat: sconcat,
      stimes: stimes,
    }
  end

  def stimes_default(cct, n, x) when n > 0, do: sdgf(cct, x, n)

  # exponentiation by squaring
  import Integer
  def sdgf(cct, x, n) when is_even(n), do: sdgf(cct, cct.(x, x), div(n, 2))
  def sdgf(_,   x, 1),                 do: x
  def sdgf(cct, x, n),                 do: sdgg(cct, cct.(x, x), div(n, 2), x)

  def sdgg(cct, x, n, z) when is_even(n), do: sdgg(cct, cct.(x, x), div(n, 2), z)
  def sdgg(cct, x, 1, z),                 do: cct.(x, z)
  def sdgg(cct, x, n, z),                 do: sdgg(cct, cct.(x, x), div(n, 2), cct.(x, z))
end
