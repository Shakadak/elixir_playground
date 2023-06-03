defmodule Access.Map do
  @doc """
  Access values of a map.
  This does not implement the handling of pop.
  """
  def vs, do: &vs/3

  def vs(:get, data, next) do
    Enum.map(data, fn({_, v}) -> next.(v) end)
  end

  def vs(:get_and_update, data, next) do
    zip =
      Enum.map(data, fn({k, v}) ->
        {get, update} = next.(v)
        {get, {k, update}}
      end)
    {get, update} = Enum.unzip(zip)
    {get, Map.new(update)}
  end

  @doc """
  Access values of a map according to a predicate.
  """
  def vs_filter(p), do: fn op, data, next -> vs_filter(op, data, next, p) end

  def vs_filter(:get, data, next, p) do
    data = Map.values(data)
    data = Enum.filter(data, p)
    Enum.map(data, next)
  end
  def vs_filter(:get_and_update, data, next, p) do
    zip = Enum.map(data, fn({k, v}) ->
      if p.(v) do
        {get, update} = next.(v)
        {{:keep, get}, {k, update}}
      else
        {:skip, {k, v}}
      end
    end)
    {get, update} = Enum.unzip(zip)
    get = Enum.map(Enum.filter(get, &is_tuple/1), fn({_, v}) -> v end)
    update = Map.new(update)
    {get, update}
  end

  @doc """
  Access key-value pairs of a map.
  This does not implement the handling of pop.
  """
  def kvs, do: &kvs/3

  def kvs(:get, data, next) do
    Enum.map(data, next)
  end

  def kvs(:get_and_update, data, next) do
    zip = Enum.map(data, next)
    {get, update} = Enum.unzip(zip)
    {get, Map.new(update)}
  end

  @doc """
  Access key-value pairs of a map according to a predicate.
  This does not implement the handling of pop.
  """
  def kvs_filter(p), do: fn op, data, next -> vs_filter(op, data, next, p) end

  def kvs_filter(:get, data, next, p) do
    Enum.map(Enum.filter(data, p), next)
  end

  def kvs_filter(:get_and_update, data, next, p) do
    zip =
      Enum.map(data, fn(kv) ->
        if p.(kv) do
          {get, update} = next.(kv)
          {{:keep, get}, update}
        else
          {:skip, kv}
        end
      end)
    {get, update} = Enum.unzip(zip)
    get = Enum.map(Enum.filter(get, &is_tuple/1), fn({:keep, x}) -> x end)
    update = Map.new(update)
    {get, update}
  end
end
