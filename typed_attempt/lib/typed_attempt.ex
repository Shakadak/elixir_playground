defmodule TypedAttempt do
  import Circe

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

  def type_to_string({params, return}) do
    params_ast = Enum.map(params, &to_ast/1)
    return_ast = to_ast(return)
    type = Macro.to_string([{:->, [], [params_ast, return_ast]}])
    type
  end

  def print_types!(module) do
    fetch_types!(module)
    |> Enum.map_join("\n", fn {{function, _arity}, type} ->
      "#{function} : #{type_to_string(type)}"
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
    debug? = false
    if debug? do
      IO.inspect(x)
      IO.inspect(y)
    end

    ~m/#{function}(#{...params})/ = x
    params = case params do
      xs when is_list(xs) -> xs
      nil -> []
    end
    arity = length(params)
    module = __CALLER__.module
    module_types = Module.get_attribute(module, :types, %{})
    type = Map.fetch!(module_types, {function, arity})
    {param_types, return_type} = type
    params = Enum.map(params, fn {_name, _meta, context} = ast when is_atom(context) ->
      Macro.update_meta(ast, &Keyword.delete(&1, :line))
    end)
    typing_env =
      %{
        vars: Map.new(Enum.zip(params, param_types)),
        functions: module_types,
      }
      #|> IO.inspect(label: "initial typing_env")

    body = case y do
      [do: {:__block__, _meta, body}] when is_list(body) -> body
      [do: body] -> [body]
    end

    _ = Enum.reduce(body, {:void, typing_env}, fn expression, {_, typing_env} ->
      {_expression_type, _typing_env} = unify_type!(expression, typing_env)
    end)
    |> case do
      {^return_type, _typing_env} -> :ok
      {unified_type, _typing_env} ->
        return_type_string = Macro.to_string(to_ast(return_type))
        unified_type_string = Macro.to_string(to_ast(unified_type))
        msg =
          """
          -- Type mismatch
          The function #{function}/#{arity} expected a type #{return_type_string} for its last expression, but instead got:
              #{Macro.to_string(:lists.last(body))} :: #{unified_type_string}
          """
        raise(msg)
    end

    z = [x, y]
        #|> IO.inspect(label: '[x, y]')
    quote do
      def unquote_splicing(z)
    end
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end

  def comparable_var(var) do
    Macro.update_meta(var, &Keyword.delete(&1, :line))
  end

  def unify_type!(expression, env) do
    case expression do
      x when is_integer(x) -> {:int, env}
      x when is_float(x) -> {:float, env}
      x when is_atom(x) -> {:atom, env}
      x when is_binary(x) -> {:binary, env}

      {l, r} ->
        {l_type, env} = unify_type!(l, env)
        {r_type, env} = unify_type!(r, env)
        {{:tuple, [l_type, r_type]}, env}

      ~m/#{{_, _, c} = var} = #{expression}/ when is_atom(c) ->
        var = comparable_var(var)
        {var_type, env} = unify_type!(expression, env)
        env = put_in(env, [:vars, var], var_type)
        {var_type, env}

      ~m/#{function}(#{...params})/ ->
        {param_types, return_type} = Map.fetch!(env.functions, {function, length(params)})

        _ = Enum.zip_with(params, param_types, fn expression, expected_type ->
          {expression_type, _env} = case expression do
            {_name, _meta, context} = var when is_atom(context) ->
              var = Macro.update_meta(var, &Keyword.delete(&1, :line))
              var_type = Map.fetch!(env.vars, var)
              {var_type, env}

            expression -> unify_type!(expression, env)
          end
          case expression_type do
            ^expected_type -> :ok
          end
        end)

        {return_type, env}
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

  def from_ast({name, _meta, []}), do: name
  def from_ast({name, _meta, [_|_] = args}), do: {name, Enum.map(args, &from_ast/1)}

  def to_ast({name, args}), do: {name, [], Enum.map(args, &to_ast/1)}
  def to_ast(name) when is_atom(name), do: {name, [], []}

  def ast_to_type(type) do
    ~m/(#{...parameters} -> #{return})/ = type
    parameters = Enum.map(parameters, &from_ast/1)
    return = from_ast(return)
    {parameters, return}
  end

  def extract_function_name({function, _, context}) when is_atom(context), do: function

  defmacro typ(~m/#{function} :: #{type}/) do
    function = extract_function_name(function)
    type = {parameters, _} = ast_to_type(type)
    arity = length(parameters)
    _ = save_type({function, arity}, type, __CALLER__.module)
    nil
  end

  defmacro foreign(~m/import #{module}.#{function} :: (#{type})/) do
    type = {parameters, _} = ast_to_type(type)
    arity = length(parameters)
    _ = save_type({function, arity}, type, __CALLER__.module)

    args = Macro.generate_arguments(arity, __CALLER__.module)
    quote do
      import unquote(module), except: [{unquote(function), unquote(arity)}]
      def unquote(function)(unquote_splicing(args)), do: unquote(module).unquote(function)(unquote_splicing(args))
    end
  end
end
