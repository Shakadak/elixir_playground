defmodule Bind do
  @doc """
  require Bind
  Bind.m BindImplementation do
    x = expression1
    y <- monadic_expression2
    BindImplementation.pure(expression(x, y))
  end
  """
  defmacro m(module, do: block) do
    body = case block do
      {:__block__, _context, body} when is_list(body) -> body
      body when is_list(body) -> body
      {:<-, _, _} = bad_body -> [bad_body]
    end
    rec_mdo(module, body)
    # |> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end

  def rec_mdo(_module, [{:<-, context, _}]) do
    description =
      "End of do notation should be a monadic expression, not a binding statement."
    line = Keyword.fetch!(context, :line)
    raise CompileError, line: line, description: description
  end

  def rec_mdo(_module, []) do
    raise "do notation cannot be empty"
  end

  def rec_mdo(_module, [{:=, context, [_binding, _expression]}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic do should be a monadic value"
  end

  def rec_mdo(_module, [line]) do
    line
  end

  def rec_mdo(module, [{:<-, _context, [binding, expression]} | tail]) do
    quote location: :keep do
      unquote(expression)
      |> unquote(module)._Bind(fn unquote(binding) ->
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
      |> unquote(module)._Bind(fn _ ->
        unquote(rec_mdo(module, tail))
      end)
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end
end
