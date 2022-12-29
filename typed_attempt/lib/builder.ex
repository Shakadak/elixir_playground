defmodule Builder do
  import Circe

  alias DataTypes, as: DT
  require DT

  def ast_to_string(ast, opts \\ []) do
    {line_length, opts} = Keyword.pop(opts, :line_length, 98)
    doc = Inspect.Algebra.format(Code.quoted_to_algebra(ast, opts), line_length)
    IO.iodata_to_binary(doc)
  end

  def expr_type_to_string(expr, type) do
    {ast, quants} = type_to_ast(type)
    if Enum.empty?(quants) do
      [-: ast]
    else
      [V: Enum.map(quants, &{&1, [], nil}), -: ast]
    end
    |> case do x -> {:typ, [], [expr, x]} end
    |> ast_to_string(locals_without_parens: [typ: 2])
  end

  def remove_brackets(type_string) do
    type_string
    |> String.trim("[")
    |> String.trim("]")
  end

  def type_to_string(type) do
    {ast, quants} = type_to_ast(type)
    if Enum.empty?(quants) do
      ast
    else
      [V: Enum.map(quants, &{&1, [], nil}), -: ast]
    end
    |> Macro.to_string()
    |> remove_brackets()
  end

  def pattern_type_mismatch(ast, unified_type, expected_type, caller) do
    unified_type_string = expr_type_to_string(ast, unified_type)
    expected_type_string = expr_type_to_string(ast, expected_type)
    msg =
      """
      -- Type mismatch
      The pattern #{Macro.to_string(ast)} expected #{expected_type_string} as its expression, but instead got:
          #{unified_type_string}
      """
    raise(CompileError, file: caller.file, line: caller.line, description: msg)
  end

  def unnest_whens(~m/#{x} when #{whens}/), do: [x | unnest_whens(whens)]
  def unnest_whens(x), do: [x]

  def zip_param(param, type, caller) do
    case {param, type} do
      {[], DT.hkt(:list, _)} -> []
      {x, DT.type(:int)} when is_integer(x) -> []
      {x, DT.type(:atom)} when is_atom(x) -> []
      {x, DT.type(:binary)} when is_binary(x) -> []
      {{_name, _meta, context} = var, type} when is_atom(context) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        [{var, type}]

      {~m/[#{x} | #{xs}]/, DT.hkt(:list, [sub_type]) = type} ->
        zip_param(x, sub_type, caller) ++ zip_param(xs, type, caller)

      {~m/#{l} = #{r}/, type} ->
        zip_param(l, type, caller) ++ zip_param(r, type, caller)

      {ast, expected_type} ->
        {unified_type, _env} = unify_type!(ast, %{}, caller)
        pattern_type_mismatch(ast, unified_type, expected_type, caller)
    end
  end

  def zip_params(params, param_types, caller) do
    Enum.zip_with(params, param_types, &zip_param(&1, &2, caller))
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
      _other -> infered
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

  def unify_type!(expression, env, caller) do
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
          :error -> raise(CompileError,
              file: caller.file,
              line: Keyword.get(meta, :line, caller.line),
              description: "Var: #{Macro.to_string(var)} (line #{Keyword.fetch!(meta, :line)}) has no previous binding.")
        end
        {var_type, env}

      {l, r} ->
        {l_type, env} = unify_type!(l, env, caller)
        {r_type, env} = unify_type!(r, env, caller)
        {DT.hkt(:tuple, [l_type, r_type]), env}

      ~m/#{{_, _, c} = var} = #{expression}/ when is_atom(c) ->
        var = comparable_var(var)
        {var_type, env} = unify_type!(expression, env, caller)
        env = put_in(env, [:vars, var], var_type)
        {var_type, env}

      [] -> {DT.hkt(:list, [DT.unknown()]), env}

      ~m/[#{x} | #{xs}]/ = ast ->
        {head_type, env} = unify_type!(x, env, caller)
        expected_type = DT.hkt(:list, [head_type])

        {unified_type, env} = _ret = unify_type!(xs, env, caller)

        case match_type(expected_type, unified_type, %{}) do
          :error ->
            expected_type_string = expr_type_to_string([{:|, [], [x, {:_, [], nil}]}], expected_type)
            unified_type_string = expr_type_to_string(xs, unified_type)
            [{_, meta, _}] = ast
            raise(CompileError,
              file: caller.file,
              line: Keyword.get(meta, :line, caller.line),
              description: "Could not match expected #{expected_type_string} with actual #{unified_type_string}")

          {:ok, _vars_env} ->
            {expected_type, env}
        end

      ~m(&#{{function, _meta, _ctxt}}/#{arity}) ->
        #_ = IO.inspect(function)
        #_ = IO.inspect(arity)
        DT.fun(param_types, return_type) = Map.fetch!(env.functions, {function, arity})
        type = DT.fun(param_types, return_type)
        {type, env}

      ~m/#{function}.(#{...params})/ = ast ->
        #arity = length(params)
        var2 = Macro.update_meta(function, &Keyword.delete(&1, :line))
        DT.fun(param_types, return_type) = Map.fetch!(env.vars, var2)

        {unified_param_types, _envs} =
          Enum.map(params, &unify_type!(&1, env, caller))
          |> Enum.unzip()
        case match_args(param_types, unified_param_types, %{}) do
          :error ->
            expected_type = Macro.to_string(Enum.map(param_types, &type_to_ast/1))
            unified_type = Macro.to_string(Enum.map(unified_param_types, &type_to_ast/1))
            {_, meta, _} = ast
            raise(CompileError,
              file: caller.file,
              line: Keyword.get(meta, :line, caller.line),
              description: "Could not match expected type: #{expected_type} with actual type: #{unified_type}")

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

      ~m/#{function}(#{...params})/ = {_, meta, _} ->
        arity = length(params)
        DT.fun(param_types, return_type) = Map.fetch!(env.functions, {function, arity})

        {unified_param_types, _envs} =
          Enum.map(params, &unify_type!(&1, env, caller))
          |> Enum.unzip()

        case match_args(param_types, unified_param_types, %{}) do
          :error ->
            expected_type = Enum.join(Enum.map(param_types, &type_to_string/1), ", ")
            unified_type = Enum.join(Enum.map(unified_param_types, &type_to_string/1), ", ")
            raise(CompileError,
              file: caller.file,
              line: Keyword.get(meta, :line, caller.line),
              description: "Could not match expected type: #{expected_type} with actual type: #{unified_type}")

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
      raise(CompileError,
        file: env.file,
        line: env.line,
        description: "Type for #{inspect(module)}.#{function}/#{inspect(arity)} already exist : #{type_to_string(type1)} (would be replaced with : #{type_to_string(type)}")
    end)
    _ = Module.put_attribute(module, :types, types)
  end

  def type_to_ast(type) do
    case type do
      DT.variable(name) -> {{name, [], nil}, MapSet.new([name])}
      DT.rigid_variable(name) -> {{name, [], nil}, MapSet.new([name])}
      DT.hkt(name, args) ->
        {args, quants} = Enum.map_reduce(args, MapSet.new(), fn arg, quants ->
          {arg_ast, quants2} = type_to_ast(arg)
          {arg_ast, MapSet.union(quants, quants2)}
        end)
        {{name, [], args}, quants}
      DT.type(name) -> {{name, [], []}, MapSet.new()}
      DT.fun(params, return) ->
        {params_ast, param_quants} = Enum.map_reduce(params, MapSet.new(), fn param, quants ->
          {param_ast, quants2} = type_to_ast(param)
          {param_ast, MapSet.union(quants, quants2)}
        end)
        #{params_ast, params_quants} = Enum.map(params, &type_to_ast/1)
        {return_ast, return_quants} = type_to_ast(return)
        ast = quote do (unquote_splicing(params_ast) -> unquote(return_ast)) end
        {ast, MapSet.union(param_quants, return_quants)}
    end
  end

  def from_ast(ast, quants) do
    case ast do
      {name, _meta, ctxt} when is_atom(ctxt) and is_map_key(quants.map, name) -> DT.variable(name)
      {name, _meta, []} -> DT.type(name)
      {name, _meta, [_|_] = args} -> DT.hkt(name, Enum.map(args, &from_ast(&1, quants)))
      ~m/(#{...parameters} -> #{return})/ ->
        parameters = Enum.map(parameters, &from_ast(&1, quants))
        return = from_ast(return, quants)
        DT.fun(parameters, return)
    end
  end

  def extract_function_name({function, _, context}) when is_atom(context), do: function
end
