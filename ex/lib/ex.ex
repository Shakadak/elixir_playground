defmodule Ex do
  defmacro delegate(module, opts \\ []) do
    module = Macro.expand(module, __CALLER__)
    only = Keyword.get(opts, :only, [])
    except = Keyword.get(opts, :except, [])

    functions =
      module.__info__(:functions)
      |> Enum.filter(fn x when only != [] -> x in only ; _ -> true end)
      |> Enum.filter(fn x -> x not in except end)

    signatures = Enum.map(functions, fn({name, arity}) ->
      args = case arity do
        0 -> []
        arity -> Enum.map(1..arity, fn(i) -> {:"x#{i}", [], nil} end)
      end
      {name, [], args}
    end)

    Enum.map(signatures, fn(signature) -> quote do
      defdelegate unquote(signature), to: unquote(module)
    end end)
  end
end

defmodule ExTuple do
  def fst({x, _}), do: x
  def snd({_, y}), do: y

  require Ex
  Ex.delegate(Tuple)
end

defmodule ExMap do
  require Ex
  Ex.delegate(Map, except: [replace: 3])
end

defmodule ExEnum do
  def group_by(enum, key_fun, value_fun, merge_fun), do: group_by(enum, %{key_fun: key_fun, value_fun: value_fun, merge_fun: merge_fun})
  def group_by(enum, opts) when is_list(opts), do: group_by(enum, Map.new(opts))
  def group_by(enumerable, %{key_fun: key_fun, merge_fun: merge_fun} = opts) do
    value_fun = Map.get(opts, :value_fun, fn x -> x end)
    reduce(reverse(enumerable), %{}, fn entry, acc ->
      key = key_fun.(entry)
      value = value_fun.(entry)

      case acc do
        %{^key => existing} -> Map.put(acc, key, merge_fun.(existing, value))
        %{} -> Map.put(acc, key, value)
      end
    end)
  end
  def group_by(enumerable, %{key_fun: key_fun} = opts) do
    value_fun = Map.get(opts, :value_fun, fn x -> x end)
    reduce(reverse(enumerable), %{}, fn entry, acc ->
      key = key_fun.(entry)
      value = value_fun.(entry)

      case acc do
        %{^key => existing} -> Map.put(acc, key, [value | existing])
        %{} -> Map.put(acc, key, [value])
      end
    end)
  end

  require Ex
  Ex.delegate(Enum, except: [chunk: 2, chunk: 3, chunk: 4, filter_map: 3, partition: 2, uniq: 2])
end
