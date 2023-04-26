defmodule Ast.BaseTypingTest do
  use ExUnit.Case

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
end
