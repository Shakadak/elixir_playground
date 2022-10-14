defmodule Curry do
  defmacro curry(fun, arity) do
    args = Macro.generate_unique_arguments(arity, __MODULE__)
    application = quote do unquote(fun).(unquote_splicing(args)) end

    args
    |> Enum.reverse()
    |> Enum.reduce(application, fn arg, acc ->
      quote do
        fn unquote(arg) -> unquote(acc) end
      end
    end)
    #|> case do x -> _ = IO.puts("curry/2 ->\n#{Macro.to_string(x)}") ; x end
  end

  #defmacro curry({:/, _, [{{:., _, _} = fun, meta, _}, arity]}) do
  #  true = is_integer(arity)
  #  args = Macro.generate_unique_arguments(arity, __MODULE__)
  #  application = quote do unquote({fun, meta, args}) end

  #  args
  #  |> Enum.reverse()
  #  |> Enum.reduce(application, fn arg, acc ->
  #    quote do
  #      fn unquote(arg) -> unquote(acc) end
  #    end
  #  end)
  #  |> case do x -> _ = IO.puts("curry/1 ->\n#{Macro.to_string(x)}") ; x end
  #end

  defmacro curry({:/, _, [{fun, meta, _}, arity]}) do
    true = is_integer(arity)
    args = Macro.generate_unique_arguments(arity, __MODULE__)
    application = quote do unquote({fun, meta, args}) end

    args
    |> Enum.reverse()
    |> Enum.reduce(application, fn arg, acc ->
      quote do
        fn unquote(arg) -> unquote(acc) end
      end
    end)
    #|> case do x -> _ = IO.puts("curry/1 ->\n#{Macro.to_string(x)}") ; x end
  end
end
