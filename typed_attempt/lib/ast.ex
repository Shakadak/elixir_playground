defmodule Ast do
  alias ComputationExpression, as: CE
  require CE

  alias Base.Result
  require Result

  alias   DataTypes, as: DT
  require DT

  import  Ast.Core, only: [
    app: 2,
    clause: 3,
    # lam: 2,
    # let: 2,
    lit: 1,
    # non_rec: 2,
    var: 1,
  ]

  import  Ast.Core.Typed, only: [
    app_t: 3,
    case_t: 3,
    clause_t: 4,
    lam_t: 3,
    let_t: 3,
    lit_t: 2,
    non_rec_t: 3,
    var_t: 2,
  ]

  defmacro mismatched_types(found, expected) do
    {:mismatched_types, {found, expected}}
  end

  defmacro unknown_type do
    :unknown_type
  end

  def is_output_concrete?(type) do
    IO.inspect(type, label: "is_output_concrete?")
    case type do
      DT.variable(_name) ->
        false

      _ ->
        false
    end
  end

  def infer(ast, env) do
    import Result
    case ast do
      lit(x) when is_integer(x) ->
        ok DT.type(:integer)

      var(v) ->
        Data.Map.fetch(env, v)
        |> case do
          ok found -> ok found
          error _ -> error unknown_type()
        end
    end
  end

  def check(ast, env, expected_type) do
    import Result
    case ast do
      lit(_) = ast ->
        CE.compute Result do
          let! found = infer(ast, env)
          case found do
            ^expected_type -> ok {}
            other_type -> error mismatched_types other_type, expected_type
          end
        end

      var(_) = ast ->
        CE.compute Result do
          let! found = infer(ast, env)
          case found do
            ^expected_type -> ok {}
            other_type -> error mismatched_types other_type, expected_type
          end
        end

      app(e, args) ->
        CE.compute Result do
          let! found = infer(e, env)
          is_output_concrete?(found)
          |> if do
            case found do
              DT.fun(params_type, ^expected_type) ->
                Result.zipWithM(args, params_type, &check(&1, env, &2))

              DT.fun(_params_type, other_type) ->
                error mismatched_types other_type, expected_type
            end
          else
            # backpropagate
            # then compare
          end
          ok {}
        end
    end
  end

  @spec annotate(ast, :check | :synthesize, env) :: Result.t
    when ast: any, env: any
  def annotate(ast, mode, env)

  def annotate(ast, :check = mode, env) do
    case ast do
      var(id) ->
        case Map.fetch(env, id) do
          {:ok, type} -> Result.ok(var_t(id, type))
          :error -> Result.error({:not_in_scope, id})
        end

      app(e, args) ->
        CE.compute Result do
          let! e_t = annotate(e, mode, env)
          let! args_t = Result.mapM(args, &annotate(&1, mode, env))
          pure app_t(e_t, args_t, DT.unknown())
        end

      Ast.Core.case(exprs, clauses) ->
        CE.compute Result do
          let! exprs_t = Result.mapM(exprs, &annotate(&1, mode, env))
          let! clauses_t = Result.mapM(clauses, &annotate(&1, mode, env))
          pure Ast.Core.Typed.case_t(exprs_t, clauses_t, DT.unknown())
        end

      clause(pats, guards, expr) ->
        CE.compute Result do
          let! pats_t = Result.mapM(pats, &annotate(&1, mode, env))
          let! guards_t = Result.mapM(guards, &annotate(&1, mode, env))
          let! expr_t = annotate(expr, mode, env)
          pure clause_t(pats_t, guards_t, expr_t, DT.unknown())
        end
    end
  end

  def annotate(ast, :synthesize = _mode, _env) do
    case ast do
      lit(x) when is_integer(x) -> Result.ok(lit_t(x, DT.type(:integer)))
      lit(x) when is_atom(x) -> Result.ok(lit_t(x, DT.type(:atom)))
    end
  end

  def jjjj(ast) do
    case ast do
      var_t(_, t) -> t
      lit_t(_, t) -> t
      app_t(_, _, t) -> t
      lam_t(_, _, t) -> t
      let_t(_, _, t) -> t
      non_rec_t(_, _, t) -> t
      case_t(_, _, t) -> t
      clause_t(_, _, _, t) -> t
    end
    |> case do
      :_? -> Result.error(:no_type)
      other -> Result.ok(other)
    end
  end
end
