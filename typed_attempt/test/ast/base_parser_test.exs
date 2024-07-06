defmodule Ast.BaseParserTest do
  use ExUnit.Case
  doctest Ast.BaseParser

  alias   Base.Result
  require Result

  import  Ast.Core, only: [
    app: 2,
    clause: 3,
    lam: 2,
    let: 2,
    lit: 1,
    non_rec: 2,
    var: 1,
  ]
  import  Ast.BaseParser, only: [
    expression: 0,
  ]

  test "parse 1" do
    ex_ast = quote do 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(lit(1)) = ast
  end

  test "parse x" do
    ex_ast = quote do x end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(var(:x)) = ast
  end

  test "parse 1 + 1" do
    ex_ast = quote do 1 + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var({:+, 2}), [lit(1), lit(1)])) = ast
  end

  test "parse x + 1" do
    ex_ast = quote do x + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var({:+, 2}), [var(:x), lit(1)])) = ast
  end

  test "parse x.(1)" do
    ex_ast = quote do x.(1) end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var(:x), [lit(1)])) = ast
  end

  test "parse x.(x)" do
    ex_ast = quote do x.(x) end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var(:x), [var(:x)])) = ast
  end

  test "parse x + y + z" do
    ex_ast = quote do x + y + z end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var({:+, 2}), [app(var({:+, 2}), [var(:x), var(:y)]), var(:z)])) = ast
  end

  test "parse case n do 42 ..." do
    ex_ast = quote do
      case n do
        42 -> :ok
        _ -> :error
      end
    end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(Ast.Core.case([var(:n)], [
      clause([lit(42)], [], lit(:ok)),
      clause([var(:_)], [], lit(:error))
    ])) = ast
  end

  test "parse fn -> :ok end" do
    ex_ast = quote do fn -> :ok end end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(lam([], lit(:ok))) = ast
  end

  test "parse fn i -> i end" do
    ex_ast = quote do fn i -> i end end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(lam([var(:i)], var(:i))) = ast
  end

  test "parse fn 42 -> :ok ; _ -> :error end" do
    ex_ast = quote do fn 42 -> :ok ; _ -> :error end end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(lam([var(:arg@1)],
      Ast.Core.case([var(:arg@1)], [
        clause([lit(42)], [], lit(:ok)),
        clause([var(:_)], [], lit(:error)),
      ])
    )) = ast
  end

  test "parse fn :inc, base, n -> base + n ; _, base, _ -> base end" do
    ex_ast = quote do
      fn
        :inc, base, n -> base + n
        _, base, _ -> base
      end
    end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(lam([var(:arg@1), var(:arg@2), var(:arg@3)],
      Ast.Core.case([var(:arg@1), var(:arg@2), var(:arg@3)], [
        Ast.Core.clause([lit(:inc), var(:base), var(:n)], [], app(var({:+, 2}), [var(:base), var(:n)])),
        Ast.Core.clause([var(:_), var(:base), var(:_)], [], var(:base)),
      ])
    )) = ast
  end

  test "parse if a > b do :greater else :not_greater end" do
    ex_ast = quote do
      if a > b do :greater else :not_greater end
    end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(
      Ast.Core.case([], [
        Ast.Core.clause([], [app(var({:>, 2}), [var(:a), var(:b)])], lit(:greater)),
        Ast.Core.clause([], [lit(true)], lit(:not_greater)),
      ])
    ) = ast
  end

  test "parse i = id(a) ; i + a" do
    ex_ast = quote do
      i = id(a) ; i + a
    end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])
    assert Result.ok(
      let(non_rec(var(:i), app(var({:id, 1}), [var(:a)])), app(var({:+, 2}), [var(:i), var(:a)]))
    ) = ast
  end
end
