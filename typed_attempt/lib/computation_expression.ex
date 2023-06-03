defmodule ComputationExpression do
  defmacro compute(dict, opts \\ [], do: {:__block__, _context, body}) do
    {debug?, []} = Keyword.pop(opts, :debug, false)
    rec_mdo(dict, body, __CALLER__)
    |> case do x -> if debug? do IO.puts(Macro.to_string(x)) end ; x end
  end

  def rec_mdo(_module, [{:let!, context, _}], caller) do
    kind = CompileError
    opts = [
      file: caller.file,
      line: Keyword.get(context, :line, caller.line),
      description: "End of computation expression cannot be let!",
    ]
    raise kind, opts
  end

  def rec_mdo(module, [{:pure, _, [expr]}], _) do
    quote location: :keep do
      unquote(module).pure(unquote(expr))
    end
  end

  def rec_mdo(_module, [line], _caller) do
    line
  end

  def rec_mdo(module, [{:let!, _ctxt, [{:=, _ctxt2, [binding, expression]}]} | tail], caller) do
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
