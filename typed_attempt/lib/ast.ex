defmodule Ast do
  alias Data.Result
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
    clause_t: 4,
    # lam_t: 3,
    # let_t: 3,
    lit_t: 2,
    # non_rec_t: 3,
    var_t: 2,
  ]

  def fill_types(ast, env) do
    case ast do
      lit(x) when is_integer(x) -> Result.ok(lit_t(x, DT.type(:integer)))
      lit(x) when is_atom(x) -> Result.ok(lit_t(x, DT.type(:atom)))
      var(id) ->
        case Map.fetch(env, id) do
          {:ok, type} -> Result.ok(var_t(id, type))
          :error -> Result.error({:not_in_scope, id})
        end

      app(e, args) ->
        Result.compute do
          let! e_t = fill_types(e, env)
          let! args_t = Result.mapM(args, &fill_types(&1, env))
          pure app_t(e_t, args_t, DT.unknown())
        end

      Ast.Core.case(exprs, clauses) ->
        Result.compute do
          let! exprs_t = Result.mapM(exprs, &fill_types(&1, env))
          let! clauses_t = Result.mapM(clauses, &fill_types(&1, env))
          pure Ast.Core.Typed.case_t(exprs_t, clauses_t, DT.unknown())
        end

      clause(pats, guards, expr) ->
        Result.compute do
          let! pats_t = Result.mapM(pats, &fill_types(&1, env))
          let! guards_t = Result.mapM(guards, &fill_types(&1, env))
          let! expr_t = fill_types(expr, env)
          pure clause_t(pats_t, guards_t, expr_t, DT.unknown())
        end
    end
  end
end
