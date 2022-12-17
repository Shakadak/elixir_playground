defmodule Builder do
  import Circe

  def type_to_string({params, return}) do
    params_ast = Enum.map(params, &type_to_ast/1)
    return_ast = type_to_ast(return)
    type = Macro.to_string([{:->, [], [params_ast, return_ast]}])
    type
  end

  def zip_param(param, type) do
    case {param, type} do
      {[], {:list, _}} -> []
      {x, :int} when is_integer(x) -> []
      {x, :atom} when is_atom(x) -> []
      {x, :binary} when is_binary(x) -> []
      {{_name, _meta, context} = var, type} when is_atom(context) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        [{var, type}]

      {~m/[#{x} | #{xs}]/, {:list, [sub_type]} = type} ->
        zip_param(x, sub_type) ++ zip_param(xs, type)

      {~m/#{l} = #{r}/, type} ->
        zip_param(l, type) ++ zip_param(r, type)

      {ast, expected_type} ->
        unified_type = unify_type!(ast, %{})
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
  end

  def zip_params(params, param_types) do
    Enum.zip_with(params, param_types, &zip_param/2)
    |> Enum.concat()
    |> Map.new()
  end

  def comparable_var(var) do
    Macro.update_meta(var, &Keyword.delete(&1, :line))
  end

  def map_type_variables({:"$rigid_variable", _} = x, _f) do
    x
  end
  def map_type_variables({:"$variable", name}, f) do
    f.(name)
  end
  def map_type_variables({name, params}, f) when is_list(params) do
    {name, Enum.map(params, &map_type_variables(&1, f))}
  end
  def map_type_variables({:fun, params, return}, f) do
    params = Enum.map(params, &map_type_variables(&1, f))
    {:fun, params, map_type_variables(return, f)}
  end
  def map_type_variables(name, _f) when is_atom(name) do
    name
  end

  def merge_unknowns(expected, infered) do
    case {expected, infered} do
      {type, :"$unknown"} -> type
      {{:"$variable", name}, {:"$variable", name}} -> {:"$variable", name}
      {{:"$rigid_variable", name}, {:"$rigid_variable", name}} -> {:"$rigid_variable", name}
      {{name, [_|_] = args1}, {name, [_|_] = args2}} ->
        {name, Enum.zip_with(args1, args2, &merge_unknowns/2)}
      {{:fun, params, return}, {:fun, params, return}} -> 
        {:fun, params, return}
      {name, name} when is_atom(name) -> name
    end
  end

  def match_type(type, type, env), do: {:ok, env}
  def match_type({:"$variable", name}, type, env) when :erlang.map_get(name, env) == type, do: {:ok, env}
  def match_type({:"$variable", name}, type, env) when :erlang.map_get(name, env) != type, do: :error
  def match_type({:"$variable", name}, type, env), do: {:ok, Map.put(env, name, type)}
  def match_type({name, args}, {name, args}, env), do: {:ok, env}
  def match_type({name, args}, {name, args2}, env) do
    Enum.zip(args, args2)
    |> Enum.reduce({:ok, env}, fn
      _, :error = x -> x
      {src, tgt}, {:ok, env} ->
      case match_type(src, tgt, env) do
        {:ok, env} -> {:ok, env}
        :error -> :error
      end
    end)
  end
  def match_type({:fun, params, return}, {:fun, params, return}, env) do
    {:ok, env}
  end
  def match_type({:fun, params1, return1}, {:fun, params2, return2}, env) do
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

  #def match_type(src, tgt) do
  #  arity = length(params)
  #  {param_types, return_type} = Map.fetch!(env.functions, {function, arity})

  #  _ = Enum.zip_with(Enum.with_index(params), param_types, fn {expression, ix}, expected_type ->
  #    case unify_type!(expression, env) do
  #      {^expected_type, _env} -> :ok
  #      {unified_type, _typing_env} ->
  #        expected_type_string = Macro.to_string(type_to_ast(expected_type))
  #        unified_type_string = Macro.to_string(type_to_ast(unified_type))
  #        msg =
  #          """
  #              -- Type mismatch
  #              The function #{function}/#{arity} expected a type #{expected_type_string} at parameter #{ix}, but instead got:
  #        #{Macro.to_string(expression)} :: #{unified_type_string}
  #        """
  #        raise(msg)
  #    end
  #  end)

  #  {return_type, env}
  #end

  def unify_type!(expression, env) do
    case expression do
      x when is_integer(x) -> {:int, env}
      x when is_float(x) -> {:float, env}
      x when is_atom(x) -> {:atom, env}
      x when is_binary(x) -> {:binary, env}
      x when is_boolean(x) -> {:boolean, env}

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
        {{:tuple, [l_type, r_type]}, env}

      ~m/#{{_, _, c} = var} = #{expression}/ when is_atom(c) ->
        var = comparable_var(var)
        {var_type, env} = unify_type!(expression, env)
        env = put_in(env, [:vars, var], var_type)
        {var_type, env}

      [] -> {{:list, [:"$unknown"]}, env}

      ~m/[#{x} | #{xs}]/ ->
        {head_type, env} = unify_type!(x, env)
        expected_type = {:list, [head_type]}

        {unified_type, env} = _ret = unify_type!(xs, env)

        case match_type(expected_type, unified_type, %{}) do
          :error ->
            expected_type_string = Macro.to_string(Enum.map(expected_type, &type_to_ast/1))
            unified_type_string = Macro.to_string(Enum.map(unified_type, &type_to_ast/1))
            raise("Could not match expected type: #{expected_type_string} with actual type: #{unified_type_string}")

          {:ok, _vars_env} ->
            #return_type = map_type_variables(return_type, fn var ->
            #  case Map.fetch(vars_env, var) do
            #    {:ok, x} -> x
            #    :error -> {:"$variable", var}
            #  end
            #end)
            ##|> IO.inspect(label: "#{function} :")
            {expected_type, env}

        end

        #case ret do
        #  {^expected_type, _env} = x -> x
        #  # ↓ type of []
        #  {{:list, [:"$unknown"]}, env} -> {expected_type, env}
        #  {unified_type, _env} ->
        #    _ = IO.inspect(unified_type, label: "unified_tail_type")
        #    head_type_string = Macro.to_string(type_to_ast(head_type))
        #                       |> IO.inspect(label: "head_type_string")
        #    tail_type_string = Macro.to_string(type_to_ast(unified_type) |> IO.inspect(label: "tail_type_ast"))
        #                       |> IO.inspect(label: "tail_type_string")
        #    msg =
        #      """
        #        -- Type mismatch
        #        Mismatch between head and tail type in the contruction of a list:
        #    [#{Macro.to_string(x)} :: #{head_type_string} | #{Macro.to_string(xs)} :: #{tail_type_string}]
        #    """
        #    raise(msg)
        #end

      ~m(&#{{function, _meta, _ctxt}}/#{arity}) ->
        #_ = IO.inspect(function)
        #_ = IO.inspect(arity)
        {param_types, return_type} = Map.fetch!(env.functions, {function, arity})
        type = {:fun, param_types, return_type}
        {type, env}

      ~m/#{function}.(#{...params})/ ->
        #arity = length(params)
        var2 = Macro.update_meta(function, &Keyword.delete(&1, :line))
        {:fun, param_types, return_type} = Map.fetch!(env.vars, var2)

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
                :error -> {:"$variable", var}
              end
            end)
            #|> IO.inspect(label: "#{Macro.to_string(function)} :")
            {return_type, env}
        end

      ~m/#{function}(#{...params})/ ->
        arity = length(params)
        {param_types, return_type} = Map.fetch!(env.functions, {function, arity})

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
                :error -> {:"$variable", var}
              end
            end)
            #|> IO.inspect(label: "#{function} :")
            {return_type, env}
        end

        #_ = Enum.zip_with(Enum.with_index(params), param_types, fn {expression, ix}, expected_type ->
        #  case unify_type!(expression, env) do
        #    {^expected_type, _env} -> :ok
        #    {unified_type, _typing_env} ->
        #      expected_type_string = Macro.to_string(type_to_ast(expected_type))
        #      unified_type_string = Macro.to_string(type_to_ast(unified_type))
        #      msg =
        #        """
        #        -- Type mismatch
        #        The function #{function}/#{arity} expected a type #{expected_type_string} at parameter #{ix}, but instead got:
        #            #{Macro.to_string(expression)} :: #{unified_type_string}
        #        """
        #      raise(msg)
        #  end
        #end)

        #{return_type, env}
    end
  end

  def save_type(fa, type, module) do
    types = Module.get_attribute(module, :types, %{})
    types = Map.update(types, fa, type, fn type1 ->
      {function, arity} = fa
      raise("Type for #{inspect(module)}.#{inspect(function)}/#{inspect(arity)} already exist : #{type_to_string(type1)} (would be replaced with : #{type_to_string(type)}")
    end)
    _ = Module.put_attribute(module, :types, types)
  end

  def type_to_ast({:"$variable", name}), do: {name, [], nil}
  def type_to_ast({:"$rigid_variable", name}), do: {name, [], nil}
  def type_to_ast({name, [_|_] = args}), do: {name, [], Enum.map(args, &type_to_ast/1)}
  def type_to_ast(name) when is_atom(name), do: {name, [], []}
  def type_to_ast({:fun, params, return}) do
    params_ast = Enum.map(params, &type_to_ast/1)
    return_ast = type_to_ast(return)
    quote do (unquote_splicing(params_ast) -> unquote(return_ast)) end
  end

  def from_ast({name, _meta, ctxt}) when is_atom(ctxt), do: {:"$variable", name}
  def from_ast({name, _meta, []}), do: name
  def from_ast({name, _meta, [_|_] = args}), do: {name, Enum.map(args, &from_ast/1)}
  def from_ast(~m/(#{_} -> #{_})/ = fun) do
    {params, return} = ast_to_type(fun)
    {:fun, params, return}
  end

  def ast_to_type(~m/(#{...parameters} -> #{return})/) do
    parameters = Enum.map(parameters, &from_ast/1)
    return = from_ast(return)
    {parameters, return}
  end

  def extract_function_name({function, _, context}) when is_atom(context), do: function
end
