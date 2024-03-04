defmodule Data.Map do
  @type key :: any
  @type value :: any
  @type error :: Exception.t
  @type option(x) :: {:some, x} | :none

  @doc """
  Behave the same as `Map.fetch/2`, but returns a more consistent error.
  """
  @spec fetch(map, key) :: Data.Result.t(error, value)
  def fetch(map, key) do
    try do
      Map.fetch(map, key)
      |> case do
        {:ok, a} -> {:ok, a}
        :error -> {:error, %KeyError{term: map, key: key}}
      end
    rescue
      err -> {:error, err}
    end
  end

  @doc """
  Update a value at a specific key with the result of the provided function. When the key is not a member of the map, the original map is returned.
  """
  @spec adjust(map, key, (value -> value)) :: map
  def adjust(m, k, f) do
    case m do
      %{^k => v} -> %{m | k => f.(v)}
      m -> m
    end
  end

  @spec update(map, key, (value -> option(value))) :: map
  def update(m, k, f) do
    case m do
      %{^k => v} -> f.(v)
      %{} -> :none
    end
    |> case do
      {:some, v} -> Map.put(m, k, v)
      :none -> Map.delete(m, k)
    end
  end

  @doc """
  The expression `alter(map, k, f)` alters the value `x` at key `k`, or absence thereof. `alter` can be used to insert, delete, or update a value in a Map. In short :
  ```elixir
  fetch(alter(m, k, f), k) ≈ f.(fetch(m, k))
  ```
  """
  @spec alter(map, key, (option(value) -> option(value))) :: map
  def alter(m, k, f) do
    case m do
      %{^k => v} -> f.({:some, v})
      %{} -> f.(:none)
    end
    |> case do
      {:some, v} -> Map.put(m, k, v)
      :none -> Map.delete(m, k)
    end
  end

  @doc """
  Map a function over all values in the map.
  """
  @spec map(map, (value -> any)) :: map
  def map(map, f) do
    :maps.map(map, fn _k, v -> f.(v) end)
  end

  @doc """
   map_keys(s, f) is the map obtained by applying `f` to each key of `s`.

  The size of the result may be smaller if `f` maps two or more distinct keys to the same new key. In this case the value at the last of the original keys is retained.
  """
  def map_keys(map, f) do
    Map.new(map, fn {k, v} -> {f.(k), v} end)
  end

  @doc """
  Merge for a list of maps.
  """
  def merges(xs), do: Enum.reduce(xs, fn t, acc -> Map.merge(acc, t) end)
  def merges(xs, f), do: Enum.reduce(xs, fn t, acc -> Map.merge(acc, t, f) end)
end
