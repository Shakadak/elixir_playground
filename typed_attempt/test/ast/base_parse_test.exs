defmodule Ast.BaseParserTest do
  use ExUnit.Case
  doctest Ast.BaseParser

  alias   Data.Result
  require Result

  import  Ast

  test "parse 1 + 1" do
    ex_ast = quote do 1 + 1 end
    ast = Ast.FromElixir.parse(ex_ast, :expr, [{Ast.BaseParser, :parse, []}])

    assert Result.ok(application(:+, [literal(1), literal(1)])) = ast
  end
end
