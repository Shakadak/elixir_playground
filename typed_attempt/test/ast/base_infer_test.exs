defmodule Ast.BaseInferTest do
  use ExUnit.Case

  alias   DataTypes, as: DT
  require DT

  alias Base.Result
  import Result

  import Ast

  import  Ast.Core, only: [
    # app: 2,
    # clause: 3,
    lam: 2,
    # let: 2,
    lit: 1,
    # non_rec: 2,
    var: 1,
  ]

  import  Ast.Core.Typed, only: [
    # app_t: 3,
    # clause_t: 4,
    # lam_t: 3,
    # let_t: 3,
    # lit_t: 2,
    # non_rec_t: 3,
    # var_t: 2,
  ]

  test "infer 1 = integer" do
    ast = lit(1)
    int = DT.type(:integer)
    env = %{}

    assert ok(^int) = Wrapped.ResultState.evalStateT(Ast.infer(ast), env)
  end

  test "infer fn x -> x end = a -> a" do
    ast = lam([var(:x)], [var(:x)])
    int = DT.type(:integer)
    env = %{}

    assert ok(^int) = Wrapped.ResultState.evalStateT(Ast.infer(ast), env)
  end

end
