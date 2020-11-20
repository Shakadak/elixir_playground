defmodule Foldable do
  @typedoc """
  Functor dictionary

  intuitive type: fmap : f (a -> b) -> f a -> f b

  * `fmap`: (f a, a -> b) -> f b # params are swapped to facilitate piping, mandatory
  * `lift_left`: a -> f b -> f a # default implementation provided, optional
  """
  @type t :: %__MODULE__{
  }

  def __struct__, do: %{
    __struct__: __MODULE__,
    fold: fn _, _ -> raise("Foldable: missing definition for fold") end,
    foldMap: fn _, _, _ -> raise("Foldable: missing definition for foldMap") end,
    foldr: fn _, _, _ -> raise("Foldable: missing definition for foldr") end,
    foldl: fn _, _, _ -> raise("Foldable: missing definition for foldl") end,
    foldr1: fn _, _ -> raise("Foldable: missing definition for foldr1") end,
    foldl1: fn _, _ -> raise("Foldable: missing definition for foldl1") end,
    toList: fn _ -> raise("Foldable: missing definition for toList") end,
    null: fn _ -> raise("Foldable: missing definition for null") end,
    length: fn _ -> raise("Foldable: missing definition for length") end,
    elem: fn _, _, _ -> raise("Foldable: missing definition for elem") end,
    maximum: fn _, _ -> raise("Foldable: missing definition for maximum") end,
    minimum: fn _, _ -> raise("Foldable: missing definition for minimum") end,
    sum: fn _, _ -> raise("Foldable: missing definition for sum") end,
    product: fn _, _ -> raise("Foldable: missing definition for product") end,
  }

  def __struct__(kv) do
    required_keys = [
      :fold,
      :foldMap,
      :foldr,
      :foldl,
      :foldr1,
      :foldl1,
      :toList,
      :null,
      :length,
      :elem,
      :maximum,
      :minimum,
      :sum,
      :product,
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

    {foldMap, foldr} = case base_dict do
      %{foldMap: foldMap, foldr: foldr} -> {foldMap, foldr}
      %{foldMap: foldMap} ->
        foldr = fn t, z, f -> appEndo(foldMap.(t, fn x -> endo(fn y -> f.(x, y) end) end, monoid_endo())).(z) end
        {foldMap, foldr}

      #%{foldMap: foldMap} ->
      #  foldr = fn f, z, t ->
      #    foldMap.(monoid_endo(), fn x -> {:Endo, fn y -> f.(x, y) end} end, t)
      #    |> case do {:Endo, g} -> g.(z) end
      #  end
      #  {foldMap, foldr}

      %{foldr: foldr} ->
        foldMap = fn t, f, monoid_dict -> foldr.(t, monoid_dict.mempty, fn x, acc -> monoid_dict.mappend.(f.(x), acc) end) end
        {foldMap, foldr}

      %{} -> raise("#{__MODULE__} minimal definition require either foldMap or foldr")
    end

    fold = Map.get(base_dict, :fold, fn t, monoid_dict -> foldMap.(t, fn x -> x end, monoid_dict) end)

    foldl = Map.get(base_dict, :foldl, fn t, z, f -> appEndo(getDual(foldMap.(t, fn x -> dual(endo(fn y -> f.(y, x) end)) end, monoid_dual(monoid_endo())))).(z) end)

    foldr1 = Map.get(base_dict, :foldr1, fn t, f ->
      mf = fn x, m ->
        result = case m do
          :Nothing   -> x
          {:Just, y} -> f.(x, y)
        end
        {:Just, result}
      end

      case foldr.(t, :Nothing, mf) do
        :Nothing   -> raise("foldr1: empty structure")
        {:Just, x} -> x
      end
    end)

    foldl1 = Map.get(base_dict, :foldl1, fn t, f ->
      mf = fn m, y ->
        result = case m do
          :Nothing   -> y
          {:Just, x} -> f.(x, y)
        end
        {:Just, result}
      end

      case foldl.(t, :Nothing, mf) do
        :Nothing   -> raise("foldr1: empty structure")
        {:Just, x} -> x
      end
    end)

    toList = Map.get(base_dict, :toList, fn t -> foldr.(t, [], fn x, acc -> [x | acc] end) end)

    null = Map.get(base_dict, :null, fn t -> foldr.(t, true, fn _, _ -> false end) end)

    length = Map.get(base_dict, :length, fn t -> foldl.(t, 0, fn acc, _ -> acc + 1 end) end)

    elem = Map.get(base_dict, :elem, fn t, x, eq_dict -> foldMap.(t, fn y -> eq_dict.==.(x, y) end, monoid_any()) end)

    maximum = Map.get(base_dict, :maximum, fn t, ord_dict -> case getMax(foldMap.(t, fn x -> max({:Just, x}) end, monoid_max(ord_dict))) do
      :Nothing   -> raise("maximum: empty structure")
      {:Just, x} -> x
    end end)

    minimum = Map.get(base_dict, :maximum, fn t, ord_dict -> case getMin(foldMap.(t, fn x -> min({:Just, x}) end, monoid_min(ord_dict))) do
      :Nothing   -> raise("maximum: empty structure")
      {:Just, x} -> x
    end end)

    sum = Map.get(base_dict, :sum, fn t, num_dict -> fold.(t, monoid_sum(num_dict)) end)

    product = Map.get(base_dict, :product, fn t, num_dict -> fold.(t, monoid_product(num_dict)) end)

    %__MODULE__{
      fold: fold,
      foldMap: foldMap,
      foldr: foldr,
      foldl: foldl,
      foldr1: foldr1,
      foldl1: foldl1,
      toList: toList,
      null: null,
      length: length,
      elem: elem,
      maximum: maximum,
      minimum: minimum,
      sum: sum,
      product: product,
    }
  end

  def endo(f), do: {:Endo, f}
  def appEndo({:Endo, f}), do: f

  def semigroup_endo do
    Semigroup.define(<>: fn {:Endo, f}, {:Endo, g} -> {:Endo, fn x -> f.(g.(x)) end} end)
  end

  def monoid_endo do
    Monoid.define(
      semigroup: semigroup_endo(),
      mempty: {:Endo, fn x -> x end}
    )
  end

  def dual(x), do: {:Dual, x}
  def getDual({:Dual, x}), do: x

  def semigroup_dual(semigroup_a) do
    Semigroup.define(
      <>: fn {:Dual, x}, {:Dual, y} -> {:Dual, semigroup_a.<>.(y, x)} end,
      stimes: fn {:Dual, x}, n -> {:Dual, semigroup_a.stimes.(x, n)} end
    )
  end

  def monoid_dual(monoid_a) do
    Monoid.define(
      semigroup: semigroup_dual(monoid_a.semigroup),
      mempty: {:Dual, monoid_a.mempty}
    )
  end

  def monoid_any do
    Monoid.define(
      semigroup: Semigroup.define(<>: &or/2),
      mempty: false,
      mconcat: fn xs -> Enum.reduce_while(xs, false, fn x, acc -> if x or acc, do: {:halt, true}, else: {:cont, false} end) end
    )
  end

  def max(x), do: {:Max, x}
  def getMax({:Max, x}), do: x

  def monoid_max(ord_dict) do
    Monoid.define(
      semigroup: Semigroup.define(<>: fn
        l                     , {:Max, :Nothing}       -> l
        {:Max, :Nothing}      , r                      -> r
        {:Max, {:Just, x}} = l, {:Max, {:Just, y}} = r -> if ord_dict.>=.(x, y), do: l, else: r
      end),
      mempty: {:Max, :Nothing}
    )
  end

  def min(x), do: {:Min, x}
  def getMin({:Min, x}), do: x

  def monoid_min(ord_dict) do
    Monoid.define(
      semigroup: Semigroup.define(<>: fn
        l                     , {:Min, :Nothing}       -> l
        {:Min, :Nothing}      , r                      -> r
        {:Min, {:Just, x}} = l, {:Min, {:Just, y}} = r -> if ord_dict.<=.(x, y), do: l, else: r
      end),
      mempty: {:Min, :Nothing}
    )
  end

  def monoid_sum(num_dict) do
    Monoid.define(
      semigroup: Semigroup.define(<>: num_dict.+),
      mempty: 0
    )
  end

  def monoid_product(num_dict) do
    Monoid.define(
      semigroup: Semigroup.define(<>: num_dict.*),
      mempty: 1
    )
  end
end
