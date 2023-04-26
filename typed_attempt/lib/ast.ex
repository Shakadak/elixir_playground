defmodule Ast do
  alias Data.Result
  require Result

  alias   DataTypes, as: DT
  require DT

  import  Ast.Core, only: [
    app: 2,
    # clause: 3,
    # lam: 2,
    # let: 2,
    lit: 1,
    # non_rec: 2,
    var: 1,
  ]

  import  Ast.Core.Typed, only: [
    app_t: 3,
    # clause_t: 4,
    # lam_t: 3,
    # let_t: 3,
    lit_t: 2,
    # non_rec_t: 3,
    var_t: 2,
  ]

  def fill_types(ast, env) do
    case ast do
      lit(x) when is_integer(x) -> Result.ok(lit_t(x, DT.type(:integer)))
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
    end
  end
end
