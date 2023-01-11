defmodule Builder.Unify do
  import  Circe

  alias   Data.Result
  import  Result

  alias   DataTypes, as: DT
  require DT

  def unify_type!(expression, env) do
    case expression do
      x when is_integer(x) -> ok({DT.type(:int), env})
      x when is_float(x) -> ok({DT.type(:float), env})
      x when is_atom(x) -> ok({DT.type(:atom), env})
      x when is_binary(x) -> ok({DT.type(:binary), env})
      x when is_boolean(x) -> ok({DT.type(:boolean), env})
      [] -> ok({DT.hkt(:list, [DT.unknown()]), env})
      {_name, meta, context} = var when is_atom(context) -> on_var(var, meta, env)
      {l, r} -> on_2_tuple(l, r, env)
      ~m/#{{_, _, c} = var} = #{expression}/ when is_atom(c) -> on_bind(var, expression, env)
      ~m/[#{x} | #{xs}]/ = [{_, meta, _}] -> on_cons(x, xs, meta, env)
      ~m(&#{{function, _meta, _ctxt}}/#{arity}) = {_, meta, _} -> on_function_capture(function, arity, meta, env)
      ~m/#{function}.(#{...params})/ = ast -> on_anonymous_call(function, params, ast, env)
      ~m/#{name}(#{...params})/ = {_, meta, _} -> on_function_call(name, params, meta, env)
    end
  end

  def on_var(var, meta, env) do
    var2 = Macro.update_meta(var, &Keyword.delete(&1, :line))
    case Map.fetch(env.vars, var2) do
      {:ok, type} -> ok(type)
      :error ->
        opts = Keyword.take(meta, [:line]) ++ [
          description: "Var: #{Macro.to_string(var)} (line #{Keyword.fetch!(meta, :line)}) has no previous binding."
        ]
        error({CompileError, opts})
    end
    |> Result.map(fn type -> {type, env} end)
  end

  def on_2_tuple(l, r, env) do
    Result.compute do
      let! {l_type, env} = unify_type!(l, env)
      let! {r_type, env} = unify_type!(r, env)
      pure {DT.hkt(:tuple, [l_type, r_type]), env}
    end
  end

  def on_bind(var, expression, env) do
    unify_type!(expression, env)
    |> Result.map(fn {var_type, env} ->
      var = Builder.comparable_var(var)
      env = put_in(env, [:vars, var], var_type)
      {var_type, env}
    end)
  end

  def on_cons(x, xs, meta, env) do
    ok({head_type, env}) = unify_type!(x, env)
    expected_type = DT.hkt(:list, [head_type])

    ok({unified_type, env}) = unify_type!(xs, env)

    case Builder.match_type(expected_type, unified_type, %{}) do
      :error ->
        expected_type_string = Builder.expr_type_to_string([{:|, [], [x, {:_, [], nil}]}], expected_type)
        unified_type_string = Builder.expr_type_to_string(xs, unified_type)
        opts = Keyword.take(meta, [:line]) ++ [
          description: "Could not match expected #{expected_type_string} with actual #{unified_type_string}"
        ]
        error({CompileError, opts})

      {:ok, _vars_env} ->
        ok({expected_type, env})
        end
  end

  def on_function_call(name, params, meta, env) do
    arity = length(params)
    DT.fun(param_types, return_type) =
      case Map.fetch(env.functions, {name, arity}) do
        {:ok, type} -> type
        :error -> Map.fetch!(env.constructors, {name, arity})
      end

    Enum.map(params, &unify_type!(&1, env))
    |> Result.sequence()
    |> Result.map(&Enum.unzip/1)
    |> Result.bind(fn {unified_param_types, _envs} ->
      case Builder.match_args(param_types, unified_param_types, %{}) do
        Result.error({kind, opts}) ->
          #expected_type = Enum.join(Enum.map(param_types, &Builder.type_to_string/1), ", ")
          #unified_type = Enum.join(Enum.map(unified_param_types, &Builder.type_to_string/1), ", ")
          #opts = Keyword.take(meta, [:line]) ++ [
          #  description: "Could not match expected type: #{expected_type} with actual type: #{unified_type}"
          #]
          opts = Keyword.merge(Keyword.take(meta, [:line]), opts)
          error({kind, opts})

        {:ok, vars_env} ->
          return_type = Builder.map_type_variables(return_type, fn var ->
            case Map.fetch(vars_env, var) do
              {:ok, x} -> x
              :error -> DT.variable(var)
            end
          end)
          #|> IO.inspect(label: "#{name} :")
          ok({return_type, env})
      end
    end)
  end

  def on_anonymous_call(function, params, ast, env) do
        #arity = length(params)
    var2 = Macro.update_meta(function, &Keyword.delete(&1, :line))
    DT.fun(param_types, return_type) = Map.fetch!(env.vars, var2)

    {unified_param_types, _envs} =
      Enum.map(params, &unify_type!(&1, env))
      |> Enum.map(&from_ok!/1)
      |> Enum.unzip()

    case Builder.match_args(param_types, unified_param_types, %{}) do
      :error ->
        expected_type = Macro.to_string(Enum.map(param_types, &Builder.type_to_ast/1))
        unified_type = Macro.to_string(Enum.map(unified_param_types, &Builder.type_to_ast/1))
        {_, meta, _} = ast
        opts = Keyword.take(meta, [:line]) ++ [
          description: "Could not match expected type: #{expected_type} with actual type: #{unified_type}"
        ]
        error({CompileError, opts})

      {:ok, vars_env} ->
        return_type = Builder.map_type_variables(return_type, fn var ->
          case Map.fetch(vars_env, var) do
            {:ok, x} -> x
            :error -> DT.variable(var)
          end
        end)
        #|> IO.inspect(label: "#{Macro.to_string(function)} :")
        Result.ok({return_type, env})
    end
  end

  def on_function_capture(function, arity, meta, env) do
    case Map.fetch(env.functions, {function, arity}) do
      {:ok, DT.fun(param_types, return_type)} ->
        type = DT.fun(param_types, return_type)
        Result.ok({type, env})

      :error ->
        opts = Keyword.take(meta, [:line]) ++ [
          description: "Could not find #{function}/#{arity} in env",
        ]
        Result.error({CompileError, opts})
    end
  end
end
