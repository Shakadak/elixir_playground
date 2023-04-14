defmodule Ast.BaseParserTest do
  use ExUnit.Case
  doctest Ast.BaseParser

  alias   Data.Result
  require Result

  import  Ast.Core, only: [
    app: 2,
    lam: 2,
    lit: 1,
    var: 1,
  ]
  import  Ast.BaseParser, only: [
    expression: 0,
  ]

  test "parse 1 + 1" do
    ex_ast = quote do 1 + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var(:+), [lit(1), lit(1)])) = ast
  end

  test "parse x + 1" do
    ex_ast = quote do x + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(app(var(:+), [var(:x), lit(1)])) = ast
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

    assert Result.ok(app(var(:+), [app(var(:+), [var(:x), var(:y)]), var(:z)])) = ast
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
      Ast.Core.clause([lit(42)], [], lit(:ok)),
      Ast.Core.clause([var(:_)], [], lit(:error))
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
        Ast.Core.clause([lit(42)], [], lit(:ok)),
        Ast.Core.clause([var(:_)], [], lit(:error)),
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
        Ast.Core.clause([lit(:inc), var(:base), var(:n)], [], app(var(:+), [var(:base), var(:n)])),
        Ast.Core.clause([var(:_), var(:base), var(:_)], [], var(:base)),
      ])
    )) = ast
  end
end
