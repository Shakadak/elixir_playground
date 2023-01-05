defmodule Builder.Function do
  import Circe

  alias DataTypes, as: DT

  require DT

  def rigidify_type(type) do
    Builder.map_type_variables(type, fn name -> DT.rigid_variable(name) end)
  end

  def extract_do_list(body) do
    case body do
      [do: {:__block__, _meta, exprs}] when is_list(exprs) -> exprs
      [do: expr] -> [expr]
    end
  end

  @doc false
  def do_deft(x, y, typing_env, caller) do
    debug? = false

    {function, params, guards} = case x do
      ~m/#{function}(#{...params}) when #{guards}/ -> {function, params, Builder.unnest_whens(guards)}
      ~m/#{function}(#{...params})/ -> {function, params, []}
    end

    guards_type_constraints = Infer.Guard.constraints(guards)

    params = Builder.Function.Parameter.ensure_list(params)

    arity = length(params)

    DT.fun(param_types, return_type) =
      Map.fetch!(typing_env.functions, {function, arity})
      |> rigidify_type

    params_typing_env = %{
      constructors: typing_env.constructors,
      functions: %{},
    }
    vars = Builder.Function.Parameter.type_bindings(params, param_types, params_typing_env, guards_type_constraints, caller, function, arity)

    typing_env = Map.put(typing_env, :vars, vars)

    body = extract_do_list(y)

    {last_expression_type, _env} =
      Enum.reduce(body, {:void, typing_env}, fn expression, {_, typing_env} ->
        {_expression_type, _typing_env} = Builder.unify_type!(expression, typing_env, caller)
      end)

    {:ok, unified_type} = Builder.merge_unknowns(return_type, last_expression_type)
    _ = case Builder.match_type(return_type, unified_type, %{}) do
      {:ok, _env} -> :ok
      :error ->
        expected_type_string = Builder.expr_type_to_string({:_, [], nil}, return_type)
        unified_type_string = Builder.expr_type_to_string(List.last(body), unified_type)
        msg =
          """
          -- Type mismatch --
          The function #{function}/#{arity} expected #{expected_type_string} for its last expression, but instead got:
              #{unified_type_string}
          """
        raise(CompileError, file: caller.file, line: caller.line, description: msg)
    end

    quote do
      def unquote_splicing([x, y])
    end
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end

  def do_type(function, type, _caller) do
    quantifiers =
      Keyword.get(type, :V, [])
      |> MapSet.new(fn {name, _meta, ctxt} when is_atom(name) and is_atom(ctxt) -> name end)
    _constraints = Keyword.get(type, :C, [])
    type = DT.fun(parameters, _) = Builder.from_ast(Keyword.fetch!(type, :-), quantifiers)
    arity = length(parameters)
    {function, arity, type}
  end

end
