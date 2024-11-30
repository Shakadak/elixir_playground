defmodule Ast.FromElixir do
  alias   Base.Result
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

  def apply_parser(parser, ast, context, parsers) when is_function(parser, 3) do
    apply(parser, [ast, context, parsers])
  end
end
