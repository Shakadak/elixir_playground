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
    arity = length(params)
    module = __CALLER__.module
    module_types = Module.get_attribute(module, :types, %{})
    type = Map.fetch!(module_types, {function, arity})
    {param_types, _return_type} = type
    params = Enum.map(params, fn {_name, _meta, context} = ast when is_atom(context) ->
      Macro.update_meta(ast, &Keyword.delete(&1, :line))
    end)
    typing_env =
      Enum.zip(params, param_types)
      |> Map.new()

    body = case y do
      [do: body] when is_list(body) -> body
      [do: body] when is_tuple(body) -> [body]
    end

    _typing_env = Enum.reduce(body, typing_env, fn expression, typing_env ->
      case expression do
        ~m/#{function}(#{...params})/ ->
          {param_types, _return_type} = Map.fetch!(module_types, {function, length(params)})
          Enum.zip_with(params, param_types, fn expression, expected_type ->
            expression = Macro.update_meta(expression, &Keyword.delete(&1, :line))
            case Map.fetch!(typing_env, expression) do
              ^expected_type -> :ok
            end
          end)
      end
      typing_env
    end)

    z = [x, y]
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
