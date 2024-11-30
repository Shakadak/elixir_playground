defmodule Ast.Base.LiteralTypingTest do
  use ExUnit.Case

  alias   Base.Result
  require Result
  import  Result

  require Transformer.StateT

  alias   DataTypes, as: DT
  require DT

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

  test "check 1 = integer" do
    ok(ast) = Ast.Utils.parse(1)

    assert ok({}) = Test.Utils.check(ast, Test.Utils.int(), %{})
  end

  test "check 1 + 1 = integer" do
    ok(ast) = Ast.Utils.parse(1 + 1)

    vars = %{
      {:+, 2} => Test.Utils.add_op(),
    }
    assert ok({}) = Test.Utils.check(ast, Test.Utils.int(), vars)
  end

  test "check x + 1 = integer when x = integer" do
    ok(ast) = Ast.Utils.parse(x + 1)

    vars = %{
      {:+, 2} => Test.Utils.add_op(),
      :x => Test.Utils.int(),
    }
    assert ok({}) = Test.Utils.check(ast, Test.Utils.int(), vars)
  end

  test "check x.(1) = integer when x = integer -> integer" do
    ok(ast) = Ast.Utils.parse(x.(1))

    int = Test.Utils.int()
    fun = DT.fun([int], int)
    vars = %{
      :x => fun,
    }

    assert ok({}) = Test.Utils.check(ast, int, vars)
  end
end
