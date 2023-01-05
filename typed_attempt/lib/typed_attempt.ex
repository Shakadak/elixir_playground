defmodule TypedAttempt do
  import Circe
  alias DataTypes, as: DT
  require DT

  def fetch_types(module) do
    Keyword.get(module.__info__(:attributes), :constructors_types, [])
    ++ Keyword.get(module.__info__(:attributes), :functions_types, [])
    |> Enum.concat()
    |> case do
      [] -> {:error, "No type found in module #{inspect(module)}"}
      [_|_] = types -> {:ok, types}
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
      _ = Module.register_attribute(__CALLER__.module, :constructors_types, persist: true)
      _ = Module.register_attribute(__CALLER__.module, :functions_types, persist: true)
      #_ = IO.inspect(Module.has_attribute?(__CALLER__.module, :types), label: "has_attribute?")
    quote do
      import unquote(__MODULE__)
      import TypeDeclaration
    end
  end

  defmacro unsafe(~m/deft #{head}, #{body}/) do
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

  defmacro deft(head, body) do
    functions_types = Module.get_attribute(__CALLER__.module, :functions_types, %{})
    constructors_types =
      Module.get_attribute(__CALLER__.module, :constructors_types, %{})
    typing_env = %{
      constructors: constructors_types,
      functions: functions_types,
    }
    Builder.Function.do_deft(head, body, typing_env, __CALLER__)
  end

  #defmacro typ(~m/#{function} :: #{type}/) do
  #  function = Builder.extract_function_name(function)
  #  type = DT.fun(parameters, _) = Builder.from_ast(type)
  #  arity = length(parameters)
  #  _ = Builder.save_type({function, arity}, type, __CALLER__.module, __CALLER__)
  #  nil
  #end
  defmacro type(function, type) do
    function = Builder.extract_function_name(function)
    {function, arity, type} = Builder.Function.do_type(function, type, __CALLER__)
    _ = Builder.save_type(:function, {function, arity}, type, __CALLER__.module, __CALLER__)
    nil
  end

  defmacro foreign(~m/import #{module}.#{function}, #{type}/) do
    debug? = false
    #type = DT.fun(parameters, _) = Builder.from_ast(type)
    #arity = length(parameters)
    {function, arity, type} = Builder.Function.do_type(function, type, __CALLER__)
    _ = Builder.save_type(:function, {function, arity}, type, __CALLER__.module, __CALLER__)

    args = Macro.generate_arguments(arity, __CALLER__.module)
    quote do
      import unquote(module), except: [{unquote(function), unquote(arity)}]
      def unquote(function)(unquote_splicing(args)), do: unquote(module).unquote(function)(unquote_splicing(args))
    end
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end
end
