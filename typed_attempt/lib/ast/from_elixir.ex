defmodule Ast.FromElixir do
  alias   Data.Result
  require Result

  def parse(ex_ast, context, parsers) do
    Enum.reduce_while(parsers, Result.error([]), fn parser, Result.error(errs) ->
      case apply_parser(parser, ex_ast, context, parsers) do
        Result.ok(_) = ok -> {:halt, ok}
        Result.error(err) -> {:cont, [err | errs]}
      end
    end)
  end

  def apply_parser({m, f, as}, ast, context, parsers) do
    apply(m, f, [ast, context, parsers | as])
  end
end
