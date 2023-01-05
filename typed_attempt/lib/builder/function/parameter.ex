defmodule Builder.Function.Parameter do
  import Circe

  alias DataTypes, as: DT

  require DT

  def ensure_list(params) do
    case params do
      xs when is_list(xs) -> xs
      a when is_atom(a) -> []
    end
  end

  def type_bindings(params, param_types, params_typing_env, guards_type_constraints, caller, function, arity) do
      zip_params(params, param_types, params_typing_env, caller)
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
  end

  def zip_param(param, type, type_env, caller) do
    constructors = type_env.constructors
    case {param, type} do
      {[], DT.hkt(:list, _)} -> []
      {x, DT.type(:int)} when is_integer(x) -> []
      {x, DT.type(:atom)} when is_atom(x) -> []
      {x, DT.type(:binary)} when is_binary(x) -> []
      {{_name, _meta, context} = var, type} when is_atom(context) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        [{var, type}]

      {~m/[#{x} | #{xs}]/, DT.hkt(:list, [sub_type]) = type} ->
        zip_param(x, sub_type, type_env, caller) ++ zip_param(xs, type, type_env, caller)

      {~m/#{l} = #{r}/, type} ->
        zip_param(l, type, type_env, caller) ++ zip_param(r, type, type_env, caller)

      {~m/#{name}(#{...params})/ = ast, type} when is_map_key(constructors, {name, length(params)}) ->
        DT.fun(param_types, return_type) = ct_type =
          Map.fetch!(constructors, {name, length(params)})

        _ = case Builder.match_type(return_type, type, %{}) do
          {:ok, vars_env} ->
            param_types = for param_type <- param_types, do: Builder.map_type_variables(param_type, fn var ->
              case Map.fetch(vars_env, var) do
                {:ok, x} -> x
                :error -> DT.variable(var)
              end
            end)
            zip_params(params, param_types, type_env, caller)

          :error ->
            Builder.pattern_type_mismatch(ast, ct_type, type, caller)
        end

      {ast, expected_type} ->
        {unified_type, _env} = Builder.unify_type!(ast, type_env, caller)
        Builder.pattern_type_mismatch(ast, unified_type, expected_type, caller)
    end
  end

  def zip_params(params, param_types, type_env, caller) do
    Enum.zip_with(params, param_types, &zip_param(&1, &2, type_env, caller))
    |> Enum.concat()
    |> Map.new()
  end
end
