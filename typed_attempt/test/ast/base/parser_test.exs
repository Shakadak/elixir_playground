defmodule Ast.Base.ParserTest do
  use ExUnit.Case
  doctest Ast.BaseParser

  alias   Base.Result
  require Result

  require Ast.Utils

  import  Ast.Core, only: [
    app: 2,
    clause: 2,
    lam: 2,
    let: 2,
    lit: 1,
    non_rec: 2,
    var: 1,
  ]

  test "parse 1" do
    assert Result.ok(lit(1)) = Ast.Utils.parse(1)
  end

  test "parse x" do
    assert Result.ok(var(:x)) = Ast.Utils.parse(x)
  end

  test "parse 1 + 1" do
    assert Result.ok(app(var({:+, 2}), [lit(1), lit(1)])) = Ast.Utils.parse(1 + 1)
  end

  test "parse x + 1" do
    assert Result.ok(app(var({:+, 2}), [var(:x), lit(1)])) = Ast.Utils.parse(x + 1)
  end

  test "parse x.(1)" do
    assert Result.ok(app(var(:x), [lit(1)])) = Ast.Utils.parse(x.(1))
  end

  test "parse x.(x)" do
    assert Result.ok(app(var(:x), [var(:x)])) = Ast.Utils.parse(x.(x))
  end

  test "parse x + y + z" do
    assert Result.ok(app(var({:+, 2}), [app(var({:+, 2}), [var(:x), var(:y)]), var(:z)])) = Ast.Utils.parse(x + y + z)
  end

  test "parse case n do 42 ..." do
    ast_r = Ast.Utils.parse(case n do
      42 -> :ok
      _ -> :error
    end)

    assert Result.ok(Ast.Core.case([var(:n)], [
      clause([lit(42)], lit(:ok)),
      clause([var(:_)], lit(:error))
    ])) = ast_r
  end

  # test "parse case x do x when ..." do
  #   ast_r = Ast.Utils.parse(case x do
  #     x when x == 1 -> :ok
  #   end)

  #   assert Result.ok(Ast.Core.case([var(:x)], [
  #     gclause([var(:x)], [app(var({:==, 2}), [var(:x), lit(1)])], lit(:ok)),
  #   ])) = ast_r
  # end

  test "parse fn -> :ok end" do
    assert Result.ok(lam([], lit(:ok))) = Ast.Utils.parse(fn -> :ok end)
  end

  test "parse fn i -> i end" do
    assert Result.ok(lam([var(:i)], var(:i))) = Ast.Utils.parse(fn i -> i end)
  end

  # test "parse fn 42 -> :ok ; _ -> :error end" do
  #   ast_r = Ast.Utils.parse(fn 42 -> :ok ; _ -> :error end)

  #   assert Result.ok(lam([var(:arg@1)],
  #     Ast.Core.case([var(:arg@1)], [
  #       clause([lit(42)], lit(:ok)),
  #       clause([var(:_)], lit(:error)),
  #     ])
  #   )) = ast_r
  # end

  # test "parse fn :inc, base, n -> base + n ; _, base, _ -> base end" do
  #   ast_r = Ast.Utils.parse(fn
  #     :inc, base, n -> base + n
  #     _, base, _ -> base
  #   end)

  #   assert Result.ok(lam([var(:arg@1), var(:arg@2), var(:arg@3)],
  #     Ast.Core.case([var(:arg@1), var(:arg@2), var(:arg@3)], [
  #       Ast.Core.clause([lit(:inc), var(:base), var(:n)], app(var({:+, 2}), [var(:base), var(:n)])),
  #       Ast.Core.clause([var(:_), var(:base), var(:_)], var(:base)),
  #     ])
  #   )) = ast_r
  # end

  test "parse if a > b do :greater else :not_greater end" do
    ast_r = Ast.Utils.parse(if a > b do :greater else :not_greater end)

    assert Result.ok(
      Ast.Core.case([], [
        Ast.Core.gclause([], [app(var({:>, 2}), [var(:a), var(:b)])], lit(:greater)),
        Ast.Core.gclause([], [lit(true)], lit(:not_greater)),
      ])
    ) = ast_r
  end

  test "parse i = id(a) ; i + a" do
    ast_r = Ast.Utils.parse((i = id(a) ; i + a))

    assert Result.ok(
      let(non_rec(var(:i), app(var({:id, 1}), [var(:a)])), app(var({:+, 2}), [var(:i), var(:a)]))
    ) = ast_r
  end

  test "parse fn i -> :a ; i end" do
    ast_r = Ast.Utils.parse(fn i -> :a ; i end)

    assert Result.ok(
      lam([var(:i)], let(non_rec(var(:_), lit(:a)), var(:i)))
    ) = ast_r
  end

  test "parse id = fn x -> x end" do
    ast_r = Ast.Utils.parse(id = fn x -> x end)

    assert Result.ok(
      non_rec(var(:id), lam([var(:x)], var(:x)))
    ) = ast_r
  end

  # test "parse fn x when x > 3 -> true end" do
  #   ast_r = Ast.Utils.parse(fn
  #     x when x > 3 -> true
  #   end)

  #   assert Result.ok(lam([var(:arg@1)],
  #     Ast.Core.case([var(:arg@1)], [
  #       gclause([var(:x)], [app(var(:>), [var(:x), lit(3)])], lit(true)),
  #     ])
  #   )) = ast_r
  # end

  # test "parse fn x when x > 3 -> true ; _ -> false end" do
  #   ast_r = Ast.Utils.parse(fn
  #     x when x > 3 -> true
  #     _ -> false
  #   end)

  #   assert Result.ok(lam([var(:arg@1)],
  #     Ast.Core.case([var(:arg@1)], [
  #       gclause([var(:x)], [app(var(:>), [var(:x), lit(3)])], lit(true)),
  #       clause([var(:_)], lit(false)),
  #     ])
  #   )) = ast_r
  # end
end
