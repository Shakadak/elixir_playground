defmodule ComputationExpression do
  defmacro __using__(opts) do
    {debug?, []} = Keyword.pop(opts, :debug, false)
    quote do
      defmacro compute(do: {:__block__, _context, body}) do
        unquote(__MODULE__).rec_mdo(__MODULE__, body, __CALLER__)
        |> case do x -> if unquote(debug?) do IO.puts(Macro.to_string(x)) end ; x end
      end
    end
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
