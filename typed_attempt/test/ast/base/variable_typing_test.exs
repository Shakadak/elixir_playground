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

    int = DT.type(:integer)
    a = DT.rigid_variable(:a)
    fun = DT.fun([a], a)
    vars = %{
      :x => fun,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, int), env)
  end

  test "check x.(x) = a -> a when x = a -> a" do
    ok(ast) = Ast.Utils.parse(x.(x))

    a = DT.rigid_variable(:a)
    fun = DT.fun([a], a)
    vars = %{
      :x => fun,
    }
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    assert ok({}) = Wrapped.ResultState.evalStateT(Ast.check(ast, fun), env)
  end

  # test "type x + y + z" do
  #   ast = app(var({:+, 2}), [app(var({:+, 2}), [var(:x), var(:y)]), var(:z)])

  #   int = DT.type(:integer)
  #   plus = DT.fun([int, int], int)
  #   env = %{
  #     {:+, 2} => plus,
  #     :x => int,
  #     :y => int,
  #     :z => int,
  #   }
  #   typed_ast = Ast.fill_types(ast, env)

  #   assert Result.ok(app_t(var_t({:+, 2}, ^plus), [app_t(var_t({:+, 2}, ^plus), [var_t(:x, ^int), var_t(:y, ^int)], DT.unknown()), var_t(:z, ^int)], DT.unknown())) = typed_ast
  # end

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
