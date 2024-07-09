defmodule Ast.Utils do
  defmacro parse(ast) do
    quote do
      require Ast.BaseParser
      ast = unquote(Macro.escape(ast))
      Ast.FromElixir.parse(ast, Ast.BaseParser.expression(), [{Ast.BaseParser, :parse, []}])
    end
  end
end
