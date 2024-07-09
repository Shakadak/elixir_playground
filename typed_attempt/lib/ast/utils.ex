defmodule Ast.Utils do
  defmacro parse(ast) do
    quote do
      ast = unquote(Macro.escape(ast))
      Ast.FromElixir.parse(ast, expression(), [{Ast.BaseParser, :parse, []}])
    end
  end
end
