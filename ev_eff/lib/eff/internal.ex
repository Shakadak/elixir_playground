defmodule Eff.Internal do
  def wrap(ast, module, module, _marked) do
    ast
  end

  def wrap(ast, _calling, module, marked) do
    Macro.postwalk(ast, fn
      {op, _, _} = ast ->
        if op in marked do
          quote do unquote(module).unquote(ast) end
        else
          ast
        end
      ast -> ast
    end)
  end
end
