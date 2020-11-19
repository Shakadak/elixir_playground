defmodule Alternative do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
    applicative: Applicative.t,
    empty: (any -> any),
    some: (any -> any),
    many: (any -> any),
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    applicative: Applicative.__struct__,
    empty: fn -> raise("Alternative: missing definition for empty") end,
    <|>: fn _, _ -> raise("Alternative: missing definition for <|>") end,
    some: fn _, _ -> raise("Alternative: missing definition for some") end,
    many: fn _, _ -> raise("Alternative: missing definition for many") end,
  }

  def __struct__(kv) do
    required_keys = [:applicative, :empty, :<|>, :some, :many]
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
    empty = Map.fetch!(t, :empty)
    choice = Map.fetch!(t, :<|>)
    some = Map.get(t, :some, fn x -> some_v(x, choice, applicative) end)
    many = Map.get(t, :many, fn x -> many_v(x, choice, applicative) end)

    %__MODULE__{
      applicative: applicative,
      empty: empty,
      <|>: choice,
      some: some,
      many: many,
    }
  end

  def many_v(v, choice, applicative), do: choice.(some_v(v, choice, applicative), applicative.pure.([]))

  def some_v(v, choice, applicative), do: applicative.liftA2(fn x, xs -> [x | xs] end, v, many_v(v, choice, applicative))
end
