defmodule Ast.BaseParser do
  import  Circe

  require Ast.Core

  alias ComputationExpression, as: CE
  require CE

  alias   Base.Result
  require Result

  defmacro function, do: :function
  defmacro expression, do: :expression
  defmacro block, do: :block

  def parse(ast, context, parsers) do
    # _ = IO.inspect(ast, label: "parse(ast, _, _)")
    case ast do
      {:__block__, _, exprs} -> parse_block(exprs, context, parsers)
      {:., _, [_, _]} = ast when context == function() ->
        Result.pure(Ast.Core.var(ast))
      x when is_atom(x) and context == function() ->
        Result.pure(Ast.Core.var(x))
      x when is_atom(x) and context == expression() -> 
        Result.pure(Ast.Core.lit(x))

      x
      when is_integer(x)
      when is_float(x)
      when is_binary(x)
      when is_boolean(x) ->
        Result.pure Ast.Core.lit(x)

      ~m/case #{expr}, #{[do: clauses]}/ ->
        CE.compute Workflow.Result do
          let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
          let! clauses_ast = parse_clauses(clauses, context, parsers)
          pure Ast.Core.case([expr_ast], clauses_ast)
        end

      ~m/fn #{pat_list} -> #{expr} end/ ->
        IO.inspect(pat_list, label: "fn with one clause")
        CE.compute Workflow.Result do
          let! pat_list_ast = Result.mapM(pat_list, &Ast.FromElixir.parse(&1, context, parsers))
          let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
          pure Ast.Core.lam(pat_list_ast, expr_ast)
        end

      {:fn, _, [~m/(#{...pat_list} -> #{_expr})/w | _] = clauses} ->
        #args = Enum.map(1..Enum.count(pat_list), fn n -> {:"arg@#{n}", [], __MODULE__} end)
        args = Enum.map(1..Enum.count(pat_list), fn n -> Ast.Core.var(:"arg@#{n}") end)
        CE.compute Workflow.Result do
          let! clauses_ast = parse_clauses(clauses, context, parsers)
          pure Ast.Core.lam(args, Ast.Core.case(args, clauses_ast))
        end

      ~m(if #{cdn} do #{on_true} else #{on_false} end) ->
        CE.compute Workflow.Result do
          let! cdn_ast = Ast.FromElixir.parse(cdn, context, parsers)
          let! on_true = Ast.FromElixir.parse(on_true, context, parsers)
          let! on_false = Ast.FromElixir.parse(on_false, context, parsers)
          pure Ast.Core.case([], [
            Ast.Core.clause([], [cdn_ast], on_true),
            Ast.Core.clause([], [Ast.Core.lit(true)], on_false),
          ])
        end

      ~m/#{pat} = #{expr}/ = {_, _meta, _} ->
        CE.compute Workflow.Result do
          let! pat_ast = Ast.FromElixir.parse(pat, context, parsers)
          let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
          pure Ast.Core.non_rec(pat_ast, expr_ast)
        end

      {id, meta, ctxt} when is_atom(id) and is_list(meta) and is_atom(ctxt) ->
        Result.pure Ast.Core.var(id)

      ~m/#{fun}.(#{...args})/ = {_, _meta, _} -> parse_anon_application(fun, args, context, parsers)
      ~m/#{fun}(#{...args})/ = {_, _meta, _} -> parse_named_application(fun, args, context, parsers)
    end
  end

  def parse_anon_application(fun, args, context, parsers) do
    CE.compute Workflow.Result do
      let! fun_ast = Ast.FromElixir.parse(fun, function(), parsers)
      let! args_ast = Result.mapM(args, &Ast.FromElixir.parse(&1, context, parsers))
      pure Ast.Core.app(fun_ast, args_ast)
    end
  end

  def parse_named_application(fun, args, context, parsers) do
    CE.compute Workflow.Result do
      let! fun_ast = Ast.FromElixir.parse(fun, function(), parsers)
      let! args_ast = Result.mapM(args, &Ast.FromElixir.parse(&1, context, parsers))
      let n = length(args)
      let name_ast = case fun_ast do
        Ast.Core.var({:., _, _} = x) -> Ast.Core.var({x, n})
        Ast.Core.var(x) when is_atom(x) -> Ast.Core.var({x, n})
      end
      pure Ast.Core.app(name_ast, args_ast)
    end
  end

  def parse_clauses(clauses, context, parsers) do
    Result.mapM(clauses, fn ~m/(#{...pat_list} -> #{expr})/w ->
      CE.compute Workflow.Result do
        let! pat_list_ast = Result.mapM(pat_list, &Ast.FromElixir.parse(&1, context, parsers))
        let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
        pure Ast.Core.clause(pat_list_ast, [], expr_ast)
      end
    end)
  end

  def parse_block([], _context, _parsers) do
    Result.error("Empty do block")
  end

  def parse_block([expr], context, parsers) do
    Ast.FromElixir.parse(expr, context, parsers)
  end

  def parse_block([expr | tail], context, parsers) do
    CE.compute Workflow.Result do
      let! expr_ast = Ast.FromElixir.parse(expr, context, parsers)
      let! tail_ast = parse_block(tail, context, parsers)
      pure(case expr_ast do
        Ast.Core.non_rec(Ast.Core.var(_), _) -> Ast.Core.let(expr_ast, tail_ast)
        Ast.Core.non_rec(pat, val) -> Ast.Core.case([val], [
            Ast.Core.clause([pat], [], tail_ast),
        ])
        _ -> Ast.Core.let(Ast.Core.non_rec(Ast.Core.var(:_), expr_ast), tail_ast)
      end)
    end
  end
end
