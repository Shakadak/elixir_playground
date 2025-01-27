defmodule LambdaLifting do
  @moduledoc """
  Documentation for `LambdaLifting`.
  """

  defmacro __using__([]) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__), only: [
        lfn: 1,
        lfn: 2,
      ]
    end
  end

  def normalize_body({:__block__, _meta, body}) do
    body
  end
  def normalize_body(body) when is_list(body) do
    body
  end

  defmacro lfn(opts \\ [], do: ast) do
    do_lfn(opts, ast, __CALLER__)
  end

  def do_lfn(opts, ast, caller) do
    ast = normalize_body(ast)

    instances = Module.get_attribute(caller.module, :"$$lfn-instances", %{})
    {n, instances} = Map.get_and_update(instances, caller.function, fn 
      nil -> {0, 0 + 1}
      n   -> {n, n + 1}
    end)
    :ok = Module.put_attribute(caller.module, :"$$lfn-instances", instances)

    fun_name = case Keyword.fetch(opts, :name) do
      {:ok, name} -> name
      :error ->
        {cf_name, cf_arity} = caller.function
        :"_lfn-#{cf_name}-#{cf_arity}-#{n}"
    end

    versioned_vars = caller.versioned_vars
    versioned_args =
      Enum.sort(Map.keys(versioned_vars))
      |> Enum.map(fn {name, context} -> Macro.var(name, context) end)

    asts =
      Enum.map(ast, fn {:->, _, [pattern, expression]} ->
        # Find the variables that are defined in the pattern, they will shadow
        # the variable accessible from the outside scope.
        {_, shadowing_vars} = Macro.prewalk(pattern, MapSet.new(), fn
          {name, _, context} = ast, shadowing_vars when is_atom(name) and is_atom(context) ->
            shadowing_vars = MapSet.put(shadowing_vars, {name, context})
            {ast, shadowing_vars}

          ast, acc -> {ast, acc}
        end)

        # Replace shadowed variables with `_` to avoid matching conflicts, eg.
        # `(x, x, y)` becomes `(x, _, y)`
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

    defs = Module.get_attribute(caller.module, :"$$lfn-defs", [])
    :ok = Module.put_attribute(caller.module, :"$$lfn-defs", defs ++ asts)

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
