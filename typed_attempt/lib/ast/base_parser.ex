defmodule Ast.BaseParser do
  import  Circe

  require Monad

  require Ast

  alias Data.Result

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
        Monad.m Result do
          pat_ast <- Ast.FromElixir.parse(pat, context, parsers)
          expr_ast <- Ast.FromElixir.parse(expr, context, parsers)
          Result.pure Ast.match(pat_ast, expr_ast)
        end

      ~m/#{fun}.(#{...args})/ ->
        Monad.m Result do
          fun_ast <- Ast.FromElixir.parse(fun, context, parsers)
          args_ast <- Result.foldlM(args, [], fn ex_ast, acc ->
            Monad.m Result do
              ast <- Ast.FromElixir.parse(ex_ast, context, parsers)
              Result.pure [ast | acc]
            end
          end)
          Result.pure Ast.application(fun_ast, args_ast)
        end

      ~m/#{fun}(#{...args})/ ->
        Monad.m Result do
          fun_ast <- Ast.FromElixir.parse(fun, context, parsers)
          args_ast <- Result.foldlM(args, [], fn ex_ast, acc ->
            Monad.m Result do
              ast <- Ast.FromElixir.parse(ex_ast, context, parsers)
              Result.pure [ast | acc]
            end
          end)
          Result.pure Ast.application(fun_ast, args_ast)
        end
    end
  end
end
