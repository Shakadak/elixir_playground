defmodule Ast.BaseParser do
  import  Circe

  require Ast

  alias   Data.Result
  require Result

  defmacro function, do: :function
  defmacro expression, do: :expression

  def parse(ast, context, parsers) do
    _ = IO.inspect(ast, label: "parse(ast, _, _)")
    case ast do
      x
      when is_atom(x) ->
        case context do
          function() -> Ast.identifier(x)
          expression() -> Ast.literal(x)
        end
        |> Result.pure()

      x
      when is_integer(x)
      when is_float(x)
      when is_binary(x)
      when is_boolean(x) ->
        Result.pure Ast.literal(x)

      ~m/#{pat} = #{expr}/ ->
        Result.compute do
          let! pat_ast = Ast.FromElixir.parse(pat, context, parsers)
          let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
          Result.pure Ast.match(pat_ast, expr_ast)
        end

      {id, meta, ctxt} when is_atom(id) and is_list(meta) and is_atom(ctxt) ->
        Result.pure Ast.identifier(id)

      ~m/#{fun}.(#{...args})/ -> parse_application(fun, args, context, parsers)
      ~m/#{fun}(#{...args})/ -> parse_application(fun, args, context, parsers)
    end
  end

  def parse_application(fun, args, context, parsers) do
    Result.compute do
      let! fun_ast = Ast.FromElixir.parse(fun, function(), parsers)
      let! args_ast = Result.map_m(args, &Ast.FromElixir.parse(&1, context, parsers))
      Result.pure Ast.application(fun_ast, args_ast)
    end
  end
end
