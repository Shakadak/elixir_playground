defmodule Ast.Base.VariableTypingTest do
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


  test "check x.(1) = integer when x = a -> a" do
    ok(ast) = Ast.Utils.parse(x.(1))

    vars = %{
      :x => Test.Utils.id(),
    }

    assert ok({}) = Test.Utils.check(ast, Test.Utils.int(), vars)
  end

  test "check x.(x) = a -> a when x = a -> a" do
    ok(ast) = Ast.Utils.parse(x.(x))

    fun = Test.Utils.id()
    vars = %{
      :x => fun,
    }

    assert ok({}) = Test.Utils.check(ast, fun, vars)
  end

  test "check x + y + z" do
    ok(ast) = Ast.Utils.parse(x + y + z)

    int = Test.Utils.int()
    vars = %{
      {:+, 2} => Test.Utils.add_op(),
      :x => int,
      :y => int,
      :z => int,
    }
    assert ok({}) = Test.Utils.check(ast, int, vars)
  end
end
