defmodule TypeDeclaration do
  import Circe

  alias DataTypes, as: DT

  require DT

  defmacro data(~m/#{name}(#{...params})/, do: block) do
    debug? = false

    #_ = IO.inspect(name, label: "data:name")
    #_ = IO.inspect(params, label: "data:params")
    #_ = IO.inspect(block, label: "data:block")

    do_data(name, params, block)
    |> Enum.map(fn {name, arity, type} ->
      _ = Builder.save_type(:constructor, {name, arity}, type, __CALLER__.module, __CALLER__)

      args = Macro.generate_arguments(arity, __CALLER__.module)
      quote do
        defmacro unquote(name)(unquote_splicing(args)),
          do: {:{}, [], [unquote(name), unquote_splicing(args)]}
      end
    end)
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end

  def do_data(_name, params, block) do
    quantifiers =
      params
      |> MapSet.new(fn {name, _meta, ctxt} when is_atom(name) and is_atom(ctxt) -> name end)

    case block do
      {:__block__, _meta, body} when is_list(body) -> body
      body -> [body]
    end
    |> Enum.map(fn constructor ->
      case constructor do
        ~m/type #{{name, _, ctxt}}, #{[-: type]}/ when is_atom(ctxt) ->
          type = DT.fun(parameters, _) = Builder.from_ast(type, quantifiers)
          arity = length(parameters)

          {name, arity, type}
      end
    end)
    #|> IO.inspect(label: "data:body")
  end

  defmacro newtype(~m/#{name}(#{...params})/, do: type) do
    _ = IO.inspect(name, label: "newtype:name")
    _ = IO.inspect(params, label: "newtype:params")
    _ = IO.inspect(type, label: "newtype:type")
    nil
  end

  defmacro type_syn(~m/#{name}(#{...params})/, type) do
    _ = IO.inspect(name, label: "type_syn:name")
    _ = IO.inspect(params, label: "type_syn:params")
    _ = IO.inspect(type, label: "type_syn:type")
    nil
  end
end
