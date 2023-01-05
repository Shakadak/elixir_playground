defmodule Builder.Data do
  import Circe

  alias DataTypes, as: DT

  require DT

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
end
