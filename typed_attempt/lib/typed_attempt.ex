defmodule TypedAttempt do
  import Circe
  alias DataTypes, as: DT
  require DT

  def fetch_types(module) do
    case Keyword.fetch(module.__info__(:attributes), :types) do
      {:ok, [types]} -> {:ok, types}
      _ -> {:error, "No type found in module #{inspect(module)}"}
    end
  end

  def fetch_types!(module) do
    case fetch_types(module) do
      {:ok, types} -> types
      {:error, msg} -> raise(msg)
    end
  end

  def fetch_type!(module, function, arity) do
    fetch_types!(module)
    |> Map.fetch!({function, arity})
  end

  def print_types!(module) do
    fetch_types!(module)
    |> Enum.map_join("\n", fn {{function, _arity}, type} ->
      "#{function} : #{Builder.type_to_string(type)}"
    end)
    |> IO.puts()
  end

  defmacro __using__(_opts) do
      _ = Module.register_attribute(__CALLER__.module, :types, persist: true)
      #_ = IO.inspect(Module.has_attribute?(__CALLER__.module, :types), label: "has_attribute?")
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro unsafe(~m/det #{head}, #{body}/) do
    debug? = false

    quote do
      def unquote(head), unquote(body)
    end
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end

  # TODO Handle macro hygiene: a ≠ a

  defmacro det(x, y) do
    do_det(x, y, __CALLER__)
  end

  @doc false
  def do_det(x, y, caller) do
    debug? = false
    if debug? do
      IO.inspect(x)
      IO.inspect(y)
    end

    {function, params, guards} = case x do
      ~m/#{function}(#{...params}) when #{guards}/ -> {function, params, Builder.unnest_whens(guards)}
      ~m/#{function}(#{...params})/ -> {function, params, []}
    end
    #_ = IO.inspect(guards, label: "guards")

    guards_type_constraints =
      guards
      |> Enum.map(fn guard -> Infer.Guard.type_constraints_from_guard(guard) end)
      |> Enum.reduce(%{}, &Map.merge(&1, &2, fn
        _var, DT.alt(ts1), DT.alt(ts2) -> DT.alt(ts1 ++ ts2)
        _var, DT.alt(ts1), t -> DT.alt(ts1 ++ [t])
        _var, t, DT.alt(ts2) -> DT.alt([t] ++ ts2)
        _var, t1, t2 -> DT.alt([t1, t2])
      end))
      #|> IO.inspect(label: "guards_type_constraints")

    params = case params do
      xs when is_list(xs) -> xs
      nil -> []
    end

    arity = length(params)

    module = caller.module
    module_types = Module.get_attribute(module, :types, %{})

    DT.fun(param_types, return_type) =
      Map.fetch!(module_types, {function, arity})
      |> Builder.map_type_variables(fn name -> DT.rigid_variable(name) end)

    vars =
      Builder.zip_params(params, param_types, caller)
      #|> IO.inspect(label: "vars")
      |> Map.merge(guards_type_constraints, fn var, type, constraint ->
          case Builder.merge_unknowns(type, constraint) do
            {:ok, constrained_type} -> constrained_type
            :error ->
              expected_type_string = Builder.expr_type_to_string(var, type)
              unified_type_string = Builder.expr_type_to_string(var, constraint)
              msg =
                """
                -- Type mismatch --
                The variable `#{Macro.to_string(var)}` in the head of #{function}/#{arity} was expected to be #{expected_type_string}, but instead got:
                    #{unified_type_string}
                """
              raise(CompileError, file: caller.file, line: caller.line, description: msg)
          end
      end)

    typing_env =
      %{
        vars: vars,
        functions: module_types,
      }
      #|> IO.inspect(label: "initial typing_env")

    body = case y do
      [do: {:__block__, _meta, body}] when is_list(body) -> body
      [do: body] -> [body]
    end

    {last_expression_type, _env} =
      Enum.reduce(body, {:void, typing_env}, fn expression, {_, typing_env} ->
        {_expression_type, _typing_env} = Builder.unify_type!(expression, typing_env, caller)
      end)

    #_ = IO.inspect(last_expression_type, label: "last expression type")
    {:ok, unified_type} = Builder.merge_unknowns(return_type, last_expression_type)
    _ = case Builder.match_type(return_type, unified_type, %{}) do
      {:ok, _env} -> :ok
      :error ->
        IO.inspect(unified_type, label: "type mismatch / unified type")
        IO.inspect(return_type, label: "type mismatch / return type")
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

  #defmacro typ(~m/#{function} :: #{type}/) do
  #  function = Builder.extract_function_name(function)
  #  type = DT.fun(parameters, _) = Builder.from_ast(type)
  #  arity = length(parameters)
  #  _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)
  #  nil
  #end
  defmacro typ(function, type) do
    function = Builder.extract_function_name(function)
    {function, arity, type} = do_typ(function, type, __CALLER__)
    _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)
    nil
  end

  def do_typ(function, type, _caller) do
    quantifiers =
      Keyword.get(type, :V, [])
      |> MapSet.new(fn {name, _meta, ctxt} when is_atom(name) and is_atom(ctxt) -> name end)
    _constraints = Keyword.get(type, :C, [])
    type = DT.fun(parameters, _) = Builder.from_ast(Keyword.fetch!(type, :-), quantifiers)
    arity = length(parameters)
    {function, arity, type}
  end

  defmacro foreign(~m/import #{module}.#{function}, #{type}/) do
    #type = DT.fun(parameters, _) = Builder.from_ast(type)
    #arity = length(parameters)
    {function, arity, type} = do_typ(function, type, __CALLER__)
    _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)

    args = Macro.generate_arguments(arity, __CALLER__.module)
    quote do
      import unquote(module), except: [{unquote(function), unquote(arity)}]
      def unquote(function)(unquote_splicing(args)), do: unquote(module).unquote(function)(unquote_splicing(args))
    end
  end
end
