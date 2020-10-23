defmodule Dbg do
  defmacro dbg(ast) do
    bin_expr = "[#{__CALLER__.file}:#{__CALLER__.line}] #{Macro.to_string(ast)}"
    quote do
      x = unquote(ast)
      _ = IO.puts(:stderr, "#{unquote(bin_expr)} ==> #{inspect(x, pretty: true)}")
      x
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end
end
