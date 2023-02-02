defmodule Ast.BaseParserTest do
  use ExUnit.Case
  doctest Ast.BaseParser

  alias   Data.Result
  require Result

  import  Ast
  import  Ast.BaseParser, only: [
    expression: 0,
  ]

  test "parse 1 + 1" do
    ex_ast = quote do 1 + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(identifier(:+), [literal(1), literal(1)])) = ast
  end

  test "parse x + 1" do
    ex_ast = quote do x + 1 end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(identifier(:+), [identifier(:x), literal(1)])) = ast
  end

  test "parse x.(1)" do
    ex_ast = quote do x.(1) end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(identifier(:x), [literal(1)])) = ast
  end

  test "parse x.(x)" do
    ex_ast = quote do x.(x) end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(identifier(:x), [identifier(:x)])) = ast
  end

  test "parse x + y + z" do
    ex_ast = quote do x + y + z end
    ast = Ast.FromElixir.parse(ex_ast, expression(), [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(identifier(:+), [application(identifier(:+), [identifier(:x), identifier(:y)]), identifier(:z)])) = ast
  end
end
