defmodule Ast.BaseTypingTest do
  use ExUnit.Case

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

  test "type 1" do
    ast = lit(1)
    env = %{}
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(lit_t(1, DT.type(:integer))) = typed_ast
  end

  test "type 1 + 1" do
    ast = app(var({:+, 2}), [lit(1), lit(1)])

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    env = %{
      {:+, 2} => plus,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(app_t(var_t({:+, 2}, ^plus), [lit_t(1, ^int), lit_t(1, ^int)], DT.unknown())) = typed_ast
  end

  test "type x + 1, x missing" do
    ast = app(var({:+, 2}), [var(:x), lit(1)])

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    env = %{
      {:+, 2} => plus,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.error({:not_in_scope, :x}) = typed_ast
  end

  test "type x + 1" do
    ast = app(var({:+, 2}), [var(:x), lit(1)])

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    env = %{
      {:+, 2} => plus,
      :x => int,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(app_t(var_t({:+, 2}, ^plus), [var_t(:x, ^int), lit_t(1, ^int)], DT.unknown())) = typed_ast
  end

  test "type x.(1)" do
    ast = app(var(:x), [lit(1)])

    int = DT.type(:integer)
    fun = DT.fun([int], int)
    env = %{
      :x => fun,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(app_t(var_t(:x, ^fun), [lit_t(1, ^int)], DT.unknown())) = typed_ast
  end

  test "type x.(x)" do
    ast = app(var(:x), [var(:x)])

    a = DT.variable(:a)
    fun = DT.fun([a], a)
    env = %{
      :x => fun,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(app_t(var_t(:x, ^fun), [var_t(:x, ^fun)], DT.unknown())) = typed_ast
  end

  test "type x + y + z" do
    ast = app(var({:+, 2}), [app(var({:+, 2}), [var(:x), var(:y)]), var(:z)])

    int = DT.type(:integer)
    plus = DT.fun([int, int], int)
    env = %{
      {:+, 2} => plus,
      :x => int,
      :y => int,
      :z => int,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(app_t(var_t({:+, 2}, ^plus), [app_t(var_t({:+, 2}, ^plus), [var_t(:x, ^int), var_t(:y, ^int)], DT.unknown()), var_t(:z, ^int)], DT.unknown())) = typed_ast
  end

  test "parse case n do 42 ..." do
    ast = Ast.Core.case([var(:n)], [
      clause([lit(42)], [], lit(:ok)),
      clause([var(:_)], [], lit(:error))
    ])

    atom = DT.type(:atom)
    int = DT.type(:integer)
    env = %{
      :n => int,
    }
    typed_ast = Ast.fill_types(ast, env)

    assert Result.ok(Ast.Core.Typed.case_t([var_t(:n, ^int)], [
      clause_t([lit_t(42, ^int)], [], lit_t(:ok, ^atom), DT.unknown()),
      clause_t([var_t(:_, DT.unknown())], [], lit_t(:error, ^atom), DT.unknown())
    ], DT.unknown())) = typed_ast
  end
end
