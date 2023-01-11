defmodule Ast.BaseParser do
  import  Circe

  require Ast

  alias   Data.Result
  require Result

  def parse(ast, context, parsers) do
    case ast do
      x
      when is_integer(x)
      when is_float(x)
      when is_atom(x)
      when is_binary(x)
      when is_boolean(x) ->
        Result.pure Ast.literal(x)

      ~m/#{pat} = #{expr}/ ->
        Result.compute do
          let! pat_ast = Ast.FromElixir.parse(pat, context, parsers)
          let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
          Result.pure Ast.match(pat_ast, expr_ast)
        end

      ~m/#{fun}.(#{...args})/ ->
        Result.compute do
          let! fun_ast = Ast.FromElixir.parse(fun, context, parsers)
          let! args_ast = Result.foldlM(args, [], fn ex_ast, acc ->
            Result.compute do
              let! ast = Ast.FromElixir.parse(ex_ast, context, parsers)
              Result.pure [ast | acc]
            end
          end)
          Result.pure Ast.application(fun_ast, args_ast)
        end

      ~m/#{fun}(#{...args})/ ->
        Result.compute do
          let! fun_ast = Ast.FromElixir.parse(fun, context, parsers)
          let! args_ast = Result.foldlM(args, [], fn ex_ast, acc ->
            Result.compute do
              let! ast = Ast.FromElixir.parse(ex_ast, context, parsers)
              Result.pure [ast | acc]
            end
          end)
          Result.pure Ast.application(fun_ast, args_ast)
        end
    end
  end
end
