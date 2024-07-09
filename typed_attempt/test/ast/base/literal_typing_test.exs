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
    int = DT.type(:integer)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), Ast.empty_state())
  end

  test "check 1 + 1 = integer" do
    ok(ast) = Ast.Utils.parse(1 + 1)

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    vars = %{
      {:+, 2} => plus,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), env)
  end

  test "check x + 1 = integer when x = integer" do
    ok(ast) = Ast.Utils.parse(x + 1)

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    vars = %{
      {:+, 2} => plus,
      :x => int,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), env)
  end

  test "check x.(1) = integer when x = integer -> integer" do
    ok(ast) = Ast.Utils.parse(x.(1))

    int = DT.type(:integer)
    fun = DT.fun([int], int)
    vars = %{
      :x => fun,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), env)
  end

  test "type x + y + z" do
    ok(ast) = Ast.Utils.parse(x + y + z)

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    vars = %{
      {:+, 2} => plus,
      :x => int,
      :y => int,
      :z => int,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), env)
  end

  # test "parse case n do 42 ..." do
  #   ast = Ast.Core.case([var(:n)], [
  #     clause([lit(42)], [], lit(:ok)),
  #     clause([var(:_)], [], lit(:error))
  #   ])

  #   atom = DT.type(:atom)
  #   int = DT.type(:integer)
  #   default = DT.unknown()
  #   env = %{
  #     :n => int,
  #     :_ => default,
  #   }
  #   typed_ast = Ast.fill_types(ast, env)

  #   assert Result.ok(Ast.Core.Typed.case_t([var_t(:n, ^int)], [
  #     clause_t([lit_t(42, ^int)], [], lit_t(:ok, ^atom), DT.unknown()),
  #     clause_t([var_t(:_, ^default)], [], lit_t(:error, ^atom), DT.unknown())
  #   ], DT.unknown())) = typed_ast
  # end
end
