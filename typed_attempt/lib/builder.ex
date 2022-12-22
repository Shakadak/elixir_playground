defmodule Builder do
  import Circe

  alias DataTypes, as: DT
  require DT

  def type_to_string(type), do: Macro.to_string(type_to_ast(type))

  def pattern_type_mismatch(ast, unified_type, expected_type) do
    unified_type_string = Macro.to_string(type_to_ast(unified_type))
    expected_type_string = Macro.to_string(type_to_ast(expected_type))
    msg =
      """
      -- Type mismatch
      The pattern #{Macro.to_string(ast)} expected a type #{expected_type_string} as its expression, but instead got:
          #{Macro.to_string(ast)} :: #{unified_type_string}
      """
    raise(msg)
  end

  def unnest_whens(~m/#{x} when #{whens}/), do: [x | unnest_whens(whens)]
  def unnest_whens(x), do: [x]

  def zip_param(param, type) do
    case {param, type} do
      {[], DT.hkt(:list, _)} -> []
      {x, DT.type(:int)} when is_integer(x) -> []
      {x, DT.type(:atom)} when is_atom(x) -> []
      {x, DT.type(:binary)} when is_binary(x) -> []
      {{_name, _meta, context} = var, type} when is_atom(context) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        [{var, type}]

      {~m/[#{x} | #{xs}]/, DT.hkt(:list, [sub_type]) = type} ->
        zip_param(x, sub_type) ++ zip_param(xs, type)

      {~m/#{l} = #{r}/, type} ->
        zip_param(l, type) ++ zip_param(r, type)

      {ast, expected_type} ->
        unified_type = unify_type!(ast, %{})
        pattern_type_mismatch(ast, unified_type, expected_type)
    end
  end

  def zip_params(params, param_types) do
    Enum.zip_with(params, param_types, &zip_param/2)
    |> Enum.concat()
    |> Map.new()
  end

  def comparable_var(var) do
    Macro.update_meta(var, &Keyword.delete(&1, :line))
  end

  def map_type_variables(type, f) do
    case type do
      DT.type(_) = x -> x
      DT.rigid_variable(_) = x -> x
      DT.variable(name) -> f.(name)
      DT.hkt(name, params) ->
        DT.hkt(name, Enum.map(params, &map_type_variables(&1, f)))
      DT.fun(params, return) ->
        params = Enum.map(params, &map_type_variables(&1, f))
        DT.fun(params, map_type_variables(return, f))
    end
  end

  def merge_unknowns(expected, infered) do
    case {expected, infered} do
      {x, x} -> x
      {type, DT.unknown()} -> type
      {DT.hkt(name, args1), DT.hkt(name, args2)} ->
        DT.hkt(name, Enum.zip_with(args1, args2, &merge_unknowns/2))
    end
  end

  def match_type(type, type, env), do: {:ok, env}
  # If the type variable is already in the env, and is the same as the target type
  def match_type(DT.variable(name), type, env) when :erlang.map_get(name, env) == type, do: {:ok, env}
  # If the type variable is already in the env, but is different from the target type
  def match_type(DT.variable(name), type, env) when :erlang.map_get(name, env) != type, do: :error
  # If the type variable is not in the env, we add it
  def match_type(DT.variable(name), type, env), do: {:ok, Map.put(env, name, type)}
  def match_type(DT.hkt(name, args), DT.hkt(name, args2), env) do
    Enum.zip(args, args2)
    |> Enum.reduce({:ok, env}, fn
      _, :error = x -> x
      {src, tgt}, {:ok, env} -> match_type(src, tgt, env)
    end)
  end
  def match_type(DT.fun(params1, return1), DT.fun(params2, return2), env) do
    case match_args(params1, params2, env) do
      {:ok, env} -> match_type(return1, return2, env)
      :error -> :error
    end
  end
  def match_type(src, tgt, env) do
    _ = IO.inspect(%{src: src, tgt: tgt, env: env}, label: "match_type")
    :error
  end

  def match_args([], [], env), do: {:ok, env}
  def match_args([src | srcs], [tgt | tgts], env) do
    case match_type(src, tgt, env) do
      {:ok, env} -> match_args(srcs, tgts, env)
      :error -> :error
    end
  end

  def unify_type!(expression, env) do
    case expression do
      x when is_integer(x) -> {DT.type(:int), env}
      x when is_float(x) -> {DT.type(:float), env}
      x when is_atom(x) -> {DT.type(:atom), env}
      x when is_binary(x) -> {DT.type(:binary), env}
      x when is_boolean(x) -> {DT.type(:boolean), env}

      {_name, meta, context} = var when is_atom(context) ->
        var2 = Macro.update_meta(var, &Keyword.delete(&1, :line))
        var_type = case Map.fetch(env.vars, var2) do
          {:ok, type} -> type
          :error -> raise("Var: #{Macro.to_string(var)} (line #{Keyword.fetch!(meta, :line)}) has no previous binding.")
        end
        {var_type, env}

      {l, r} ->
        {l_type, env} = unify_type!(l, env)
        {r_type, env} = unify_type!(r, env)
        {DT.hkt(:tuple, [l_type, r_type]), env}

      ~m/#{{_, _, c} = var} = #{expression}/ when is_atom(c) ->
        var = comparable_var(var)
        {var_type, env} = unify_type!(expression, env)
        env = put_in(env, [:vars, var], var_type)
        {var_type, env}

      [] -> {DT.hkt(:list, [DT.unknown()]), env}

      ~m/[#{x} | #{xs}]/ ->
        {head_type, env} = unify_type!(x, env)
        expected_type = DT.hkt(:list, [head_type])

        {unified_type, env} = _ret = unify_type!(xs, env)

        case match_type(expected_type, unified_type, %{}) do
          :error ->
            expected_type_string = Macro.to_string(Enum.map(expected_type, &type_to_ast/1))
            unified_type_string = Macro.to_string(Enum.map(unified_type, &type_to_ast/1))
            raise("Could not match expected type: #{expected_type_string} with actual type: #{unified_type_string}")

          {:ok, _vars_env} ->
            {expected_type, env}
        end

      ~m(&#{{function, _meta, _ctxt}}/#{arity}) ->
        #_ = IO.inspect(function)
        #_ = IO.inspect(arity)
        DT.fun(param_types, return_type) = Map.fetch!(env.functions, {function, arity})
        type = DT.fun(param_types, return_type)
        {type, env}

      ~m/#{function}.(#{...params})/ ->
        #arity = length(params)
        var2 = Macro.update_meta(function, &Keyword.delete(&1, :line))
        DT.fun(param_types, return_type) = Map.fetch!(env.vars, var2)

        {unified_param_types, _envs} =
          Enum.map(params, &unify_type!(&1, env))
          |> Enum.unzip()
        case match_args(param_types, unified_param_types, %{}) do
          :error ->
            expected_type = Macro.to_string(Enum.map(param_types, &type_to_ast/1))
            unified_type = Macro.to_string(Enum.map(unified_param_types, &type_to_ast/1))
            raise("Could not match expected type: #{expected_type} with actual type: #{unified_type}")

          {:ok, vars_env} ->
            return_type = map_type_variables(return_type, fn var ->
              case Map.fetch(vars_env, var) do
                {:ok, x} -> x
                :error -> DT.variable(var)
              end
            end)
            #|> IO.inspect(label: "#{Macro.to_string(function)} :")
            {return_type, env}
        end

      ~m/#{function}(#{...params})/ ->
        arity = length(params)
        DT.fun(param_types, return_type) = Map.fetch!(env.functions, {function, arity})

        {unified_param_types, _envs} =
          Enum.map(params, &unify_type!(&1, env))
          |> Enum.unzip()

        case match_args(param_types, unified_param_types, %{}) do
          :error ->
            expected_type = Enum.join(Enum.map(param_types, &type_to_string/1), ", ")
            unified_type = Enum.join(Enum.map(unified_param_types, &type_to_string/1), ", ")
            raise("Could not match expected type: #{expected_type} with actual type: #{unified_type}")

          {:ok, vars_env} ->
            return_type = map_type_variables(return_type, fn var ->
              case Map.fetch(vars_env, var) do
                {:ok, x} -> x
                :error -> DT.variable(var)
              end
            end)
            #|> IO.inspect(label: "#{function} :")
            {return_type, env}
        end
    end
  end

  def save_type(fa, type, module, env) do
    types = Module.get_attribute(module, :types, %{})
    types = Map.update(types, fa, type, fn type1 ->
      {function, arity} = fa
      raise(CompileError, file: env.file, line: env.line, description: "Type for #{inspect(module)}.#{function}/#{inspect(arity)} already exist : #{type_to_string(type1)} (would be replaced with : #{type_to_string(type)}")
    end)
    _ = Module.put_attribute(module, :types, types)
  end

  def type_to_ast(DT.variable(name)), do: {name, [], nil}
  def type_to_ast(DT.rigid_variable(name)), do: {name, [], nil}
  def type_to_ast(DT.hkt(name, args)), do: {name, [], Enum.map(args, &type_to_ast/1)}
  def type_to_ast(DT.type(name)), do: {name, [], []}
  def type_to_ast(DT.fun(params, return)) do
    params_ast = Enum.map(params, &type_to_ast/1)
    return_ast = type_to_ast(return)
    quote do (unquote_splicing(params_ast) -> unquote(return_ast)) end
  end

  def from_ast({name, _meta, ctxt}) when is_atom(ctxt), do: DT.variable(name)
  def from_ast({name, _meta, []}), do: DT.type(name)
  def from_ast({name, _meta, [_|_] = args}), do: DT.hkt(name, Enum.map(args, &from_ast/1))
  def from_ast(~m/(#{...parameters} -> #{return})/) do
    parameters = Enum.map(parameters, &from_ast/1)
    return = from_ast(return)
    DT.fun(parameters, return)
  end

  def extract_function_name({function, _, context}) when is_atom(context), do: function
end
