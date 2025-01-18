defmodule Ast.Base.CheckTypingTest do
  use ExUnit.Case

  alias   Base.Result
  require Result
  import  Result

  require Transformer.StateT

  alias   DataTypes, as: DT
  require DT

  require Ast.Utils


  test "check case n do 42 ..." do
    ok(ast) = Ast.Utils.parse(case n do
      42 -> :ok
      _ -> :error
    end)

    vars = %{
      :n => Test.Utils.int(),
    }

    expected_type = Test.Utils.atom()

    assert ok({}) = Test.Utils.check(ast, expected_type, vars)
  end

  test "check fn n -> n + 1 end :: int -> int" do
    ok(ast) = Ast.Utils.parse(fn n -> n + 1 end)


    vars = %{
      {:+, 2} => Test.Utils.add_op(),
    }

    int = Test.Utils.int()
    expected_type = DT.fun([int], int)

    assert ok({}) = Test.Utils.check(ast, expected_type, vars)
  end
end
