defmodule LambdaLifting do
  @moduledoc """
  Documentation for `LambdaLifting`.
  """

  defmacro __using__([]) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__), only: [
        lfn: 1,
      ]
    end
  end

  def normalize_body({:__block__, _meta, body}) do
    body
  end
  def normalize_body(body) when is_list(body) do
    body
  end

  defmacro lfn(do: ast) do
    ast = normalize_body(ast)

    instances = Module.get_attribute(__CALLER__.module, :"$$lfn-instances", %{})
    {n, instances} = Map.get_and_update(instances, __CALLER__.function, fn 
      nil -> {0, 0 + 1}
      n   -> {n, n + 1}
    end)
    :ok = Module.put_attribute(__CALLER__.module, :"$$lfn-instances", instances)

    {cf_name, cf_arity} = __CALLER__.function
    fun_name = :"_lfn-#{cf_name}-#{cf_arity}-#{n}"

    versioned_vars = __CALLER__.versioned_vars
    versioned_args =
      Enum.sort(Map.keys(versioned_vars))
      |> Enum.map(fn {name, context} -> Macro.var(name, context) end)

    asts =
      Enum.map(ast, fn {:->, _, [pattern, expression]} ->
        {_, shadowing_vars} = Macro.prewalk(pattern, MapSet.new(), fn
          {name, _, context} = ast, shadowing_vars when is_atom(name) and is_atom(context) ->
            shadowing_vars = MapSet.put(shadowing_vars, {name, context})
            {ast, shadowing_vars}

          ast, acc -> {ast, acc}
        end)

        versioned_args = Enum.map(versioned_args, fn {name, meta, context} ->
          case MapSet.member?(shadowing_vars, {name, context}) do
            true  -> {:_, meta, context}
            false -> {name, meta, context}
          end
        end)

        quote do
          def unquote(fun_name)(unquote_splicing(pattern), unquote_splicing(versioned_args)) do
            unquote(expression)
          end
        end
      end)
    # |> tap(&IO.puts(Macro.to_string(&1)))

    defs = Module.get_attribute(__CALLER__.module, :"$$lfn-defs", [])
    :ok = Module.put_attribute(__CALLER__.module, :"$$lfn-defs", defs ++ asts)

    [{:->, _, [pat, _expr]}] = ast
    argsn = length(pat) + length(versioned_args)

    fun_ast = quote do
      &__MODULE__.unquote(fun_name)/unquote(argsn)
    end

    {fun_ast, versioned_args}
  end

  defmacro __before_compile__(_) do
    defs = Module.get_attribute(__CALLER__.module, :"$$lfn-defs", [])
    defs
    # |> tap(&IO.puts(Macro.to_string(&1)))
  end
end
