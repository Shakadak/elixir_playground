defmodule Ast.Utils do
  defmacro parse(ast) do
    # This is delayed because otherwise the whole test
    # file needs to compile fully. I prefer to be able
    # to work on each case individually.
    quote do
      require Ast.BaseParser
      ast = unquote(Macro.escape(ast))
      Ast.FromElixir.parse(ast, Ast.BaseParser.expression(), [&Ast.BaseParser.parse/3])
    end
  end
end
