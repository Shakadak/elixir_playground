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
    debug? = true
    if debug? do
      IO.inspect(x)
      IO.inspect(y)
    end

    {function, params, guards} = case x do
      ~m/#{function}(#{...params}) when #{guards}/ -> {function, params, Builder.unnest_whens(guards)}
      ~m/#{function}(#{...params})/ -> {function, params, []}
    end
    _ = IO.inspect(guards, label: "guards")

    params = case params do
      xs when is_list(xs) -> xs
      nil -> []
    end

    arity = length(params)

    module = caller.module
    module_types = Module.get_attribute(module, :types, %{})

    #DT.fun(param_types, return_type) = Map.fetch!(module_types, {function, arity})
    #param_types = Enum.map(param_types, &map_type_variables(&1, fn name -> DT.rigid_variable(name) end))
    #return_type = map_type_variables(return_type, fn name -> DT.rigid_variable(name) end)

    DT.fun(param_types, return_type) =
      Map.fetch!(module_types, {function, arity})
      |> Builder.map_type_variables(fn name -> DT.rigid_variable(name) end)

    vars =
      Builder.zip_params(params, param_types, caller)
      #|> IO.inspect(label: "vars")

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
    unified_type = Builder.merge_unknowns(return_type, last_expression_type)
    _ = case Builder.match_type(return_type, unified_type, %{}) do
      {:ok, _env} -> :ok
      :error ->
        IO.inspect(unified_type, label: "type mismatch / unified type")
        IO.inspect(return_type, label: "type mismatch / return type")
        expected_type_string = Builder.type_to_string(return_type)
        unified_type_string = Builder.type_to_string(unified_type)
        msg =
          """
          -- Type mismatch --
          The function #{function}/#{arity} expected a type #{expected_type_string} for its last expression, but instead got:
              #{Macro.to_string(:lists.last(body))} :: #{unified_type_string}
          """
        raise(msg)
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

  defmacro typ(~m/#{function} :: #{type}/) do
    function = Builder.extract_function_name(function)
    type = DT.fun(parameters, _) = Builder.from_ast(type)
    arity = length(parameters)
    _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)
    nil
  end

  defmacro foreign(~m/import #{module}.#{function} :: (#{type})/) do
    type = DT.fun(parameters, _) = Builder.from_ast(type)
    arity = length(parameters)
    _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)

    args = Macro.generate_arguments(arity, __CALLER__.module)
    quote do
      import unquote(module), except: [{unquote(function), unquote(arity)}]
      def unquote(function)(unquote_splicing(args)), do: unquote(module).unquote(function)(unquote_splicing(args))
    end
  end
end
