defmodule Access.Map do
  @doc """
  Access values of a map.
  """
  def vs, do: &vs/3

  def vs(:get, data, next) do
    Enum.map(data, fn({_, v}) -> next.(v) end)
  end

  def vs(:get_and_update, data, next) do
    zip =
      Enum.map(data, fn({k, v}) ->
        case next.(v) do
          {get, update} -> {get, [{k, update}]}
          :pop -> {v, []}
        end
      end)
    {get, update} = Enum.unzip(zip)
    {get, Map.new(Enum.concat(update))}
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
        case next.(v) do
          {get, update} -> {[get], [{k, update}]}
          :pop -> {[v], []}
        end
      else
        {[], [{k, v}]}
      end
    end)
    {gets, update} = Enum.unzip(zip)
    get = Enum.concat(gets)
    update = Map.new(Enum.concat(update))
    {get, update}
  end

  @doc """
  Access key-value pairs of a map.
  """
  def kvs, do: &kvs/3

  def kvs(:get, data, next) do
    Enum.map(data, next)
  end

  def kvs(:get_and_update, data, next) do
    dezipper = fn kv ->
      case next.(kv) do
        {get, update} -> {get, [update]}
        :pop -> {kv, []}
      end
    end

    {gets, updates} = Enum.unzip(Enum.map(data, dezipper))
    {gets, Map.new(Enum.concat(updates))}
  end

  @doc """
  Access key-value pairs of a map according to a predicate.
  """
  def kvs_filter(p), do: fn op, data, next -> vs_filter(op, data, next, p) end

  def kvs_filter(:get, data, next, p) do
    Enum.map(Enum.filter(data, p), next)
  end

  def kvs_filter(:get_and_update, data, next, p) do
    dezipper = fn kv ->
      if p.(kv) do
        case next.(kv) do
          {get, update} -> {[get], [update]}
          :pop -> {[kv], []}
        end
      else
        {[], [kv]}
      end
    end

    {gets, updates} = Enum.unzip(Enum.map(data, dezipper))
    get = Enum.concat(gets)
    update = Map.new(Enum.concat(updates))
    {get, update}
  end
end
