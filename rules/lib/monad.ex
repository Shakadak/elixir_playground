defmodule Monad do
  @doc """
  require Monad
  Monad.m MonadImplementation do
    x = expression1
    y <- monadic_expression2
    MonadImplementation.pure(expression(x, y))
  end
  """
  defmacro m(module, do: ast) do
    body = case ast do
      {:__block__, _context, body} -> body
      {_, _, _} = body -> [body]
    end

    rec_mdo(module, body)
    |> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end

  def rec_mdo(_module, [{:<-, context, _}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic `do` should be a monadic value"
  end

  def rec_mdo(_module, [line]) do
    line
  end

  def rec_mdo(module, [{:<-, _context, [binding, expression]} | tail]) do
    quote location: :keep do
      unquote(expression)
      |> unquote(module).bind(fn unquote(binding) ->
        unquote(rec_mdo(module, tail))
      end)
    end
  end

  def rec_mdo(module, [{:=, _context, [_binding, _expression]} = line | tail]) do
    quote location: :keep do
      unquote(line)
      unquote(rec_mdo(module, tail))
    end
  end

  def rec_mdo(module, [expression | tail]) do
    quote location: :keep do
      unquote(expression)
      |> unquote(module).bind(fn _ ->
        unquote(rec_mdo(module, tail))
      end)
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end
end
