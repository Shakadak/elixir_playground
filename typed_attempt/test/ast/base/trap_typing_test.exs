defmodule Ast.Base.TrapTypingTest do
  use ExUnit.Case

  alias   Base.Result
  require Result
  import  Result

  require Transformer.StateT

  alias   DataTypes, as: DT
  require DT

  import  Ast

  require Ast.Utils

  # import  Ast.Core.Typed, only: [
  #   app_t: 3,
  #   clause_t: 4,
  #   # lam_t: 3,
  #   # let_t: 3,
  #   lit_t: 2,
  #   # non_rec_t: 3,
  #   var_t: 2,
  # ]

  # TODO : https://stackoverflow.com/questions/53039099/why-are-there-flexible-and-rigid-bounds-in-mlf

  test "auto succ fail" do
    ok(ast) = Ast.Utils.parse(auto.(succ))

    int = DT.type(:integer)
    a = DT.rigid_variable(:a)
    succ = DT.fun([int], int)
    id = DT.fun([a], a)
    auto = DT.fun([id], id)
    #default = DT.unknown()
    vars = %{
      :auto => auto,
      :succ => succ,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert error(mismatched_types(^succ, ^id)) = Wrapped.ResultState.evalStateT(Ast.check(ast, id), env)
  end
end
