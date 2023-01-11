defmodule Monad do
  @doc """
  require Monad
  Monad.m MonadImplementation do
    x = expression1
    y <- monadic_expression2
    MonadImplementation.pure(expression(x, y))
  end
  """
  defmacro m(module, do: {:__block__, _context, body}) do
    rec_mdo(module, body, __CALLER__)
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end

  def rec_mdo(_module, [{:<-, context, _}], caller) do
    kind = CompileError
    opts = [
      file: caller.file,
      line: Keyword.get(context, :line, caller.line),
      description: "End of do notation should be a monadic value",
    ]
    raise kind, opts
  end

  def rec_mdo(_module, [line], _caller) do
    line
  end

  def rec_mdo(module, [{:<-, _context, [binding, expression]} | tail], caller) do
    quote location: :keep do
      unquote(expression)
      |> unquote(module).bind(fn unquote(binding) ->
        unquote(rec_mdo(module, tail, caller))
      end)
    end
  end

  def rec_mdo(module, [{:=, _context, [_binding, _expression]} = line | tail], caller) do
    quote location: :keep do
      unquote(line)
      unquote(rec_mdo(module, tail, caller))
    end
  end

  def rec_mdo(module, [expression | tail], caller) do
    quote location: :keep do
      unquote(expression)
      |> unquote(module).bind(fn _ ->
        unquote(rec_mdo(module, tail, caller))
      end)
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end
end
