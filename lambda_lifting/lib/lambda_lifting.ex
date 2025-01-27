defmodule LambdaLifting do
  @moduledoc """
  Anonymous functions and closures are not compiled as inline code in Erlang.

  If we take for example the function:
  ```elixir
  def my_fun(list) do
    Enum.map(list, fn element -> element + 1 end)
  end
  ```
  The anonymous function is in fact compiled as a separate function, named
  with something of the form `-my_fun-0`, which doesn't really matter as it
  can not be used directly. You can check informations about anonymous functions
  with Erlang's `:erlang.fun_info/1`.  
  This is how Erlang is capable of passing functions across nodes, it doesn't send
  code, it sends informations on how to execute the function stored in the module.

  What this module does, with its macro `lfn/2`, is repeat this exact same process,
  but explicitely.  
  Why is that ?  
  Metadata is associated to the anonymous function informations in order to ensure that
  code isn't executed with a different version. This means that if the module is
  recompiled, even if this specific anonymous function didn't change, it will still be
  considered as different code, and fail at runtime.  
  If instead we do the process of compiling the anonymous function ourselve, and store
  the expected closed over env. We can then safely pass the fonction reference, (when you
  do `&module.function/arity`) along with the closed over env to different nodes with
  different version and it will still work. That is, as long as the code on the other
  node can properly use the given data.

  It still means having to be careful when updating code, but you still get the
  convenience of colocated code.

  Using the `:name` option allows for more stability over time, as the name will not
  depend on the order of execution of the macro. And it also mean you can refactor the
  anonymous function to elsewhere, or save it for backward compatibility between versions.

  Multiclause anonymous functions are supported.

  ## Examples

  The above example can thus be redefined as such:
  ```elixir
  use LambdaLifting

  def my_fun(list) do
    Enum.map(list, lfn do element -> element + 1 end)
  end
  ```
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
