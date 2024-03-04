defmodule Monad do
  @doc """
  require Monad
  Monad.compute MonadImplementation do
    x = expression1
    y <- monadic_expression2
    MonadImplementation.pure(expression(x, y))
  end
  """
  defmacro compute(module, do: ast) do
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

defmodule Rollback do
  def erase_line do
    IO.write(IO.ANSI.format([:clear_line]))
  end
  def erase_line_above do
    IO.write(IO.ANSI.format([IO.ANSI.cursor_up(), :clear_line]))
  end

  def write(x) do
    try do
      _ = IO.write(x)
      {{:success, {}}, [&erase_line/0]}
    catch
      _, _ -> {{:failure, "Failed to execute write"}, []}
    end
  end

  def read do
    try do
      s = IO.gets("") |> String.trim()
      {{:success, s}, [&erase_line_above/0]}
    catch
      _, _ -> {{:failure, "Failed to execute read"}, []}
    end
  end

  def prompt(x) do
    write(x)
    |> bind(fn _ -> read() end)
    |> on_failure(fn _ -> "Failed to execute prompt" end)
  end

  def print(x) do
    try do
      _ = IO.puts(x)
      {{:success, {}}, [&erase_line_above/0]}
    catch
      _, _ -> {{:failure, "Failed to execute print"}, []}
    end
  end

  def print_range(r) do
    Enum.to_list(r)
    |> Enum.reduce_while({{:success, []}, []}, fn x, {{:success, xs}, rbs} ->
      case print(x) do
        {{:success, x}, rbns} -> {:cont, {{:success, [x | xs]}, rbns ++ rbs}}
        {{:failure, _}, rbns} -> {:halt, {{:failure, "Failed to finish print_range"}, rbns ++ rbs}}
      end
    end)
    |> case do
      {{:success, xs}, rbs} -> {{:success, Enum.reverse(xs)}, rbs}
      failure -> failure
    end
  end

  def parse_age(bin) do
    Integer.parse(bin)
    |> case do
      {age, ""} -> {:ok, age}
      _ -> {:error, "Failed to parse age"}
    end
  end

  def ask_name do
    prompt("Hello, what's your name ? ")
    |> on_failure(fn _ -> "failed to get the name" end)
  end

  def greet(name) do
    print("Nice to meet you #{name} !")
    |> on_failure(fn _ -> "failed to greet back the user" end)
  end

  def ask_age do
    prompt("How old are you ? ")
    |> on_failure(fn _ -> "failed to get the age of the user" end)
  end

  def count_up(age) do
    print("#{age} ? Let me count on my digits to see how much that is.")
    |> on_failure(fn _ -> "failed to inform the user of the imminent count up" end)
    |> bind(fn {} ->
      print_range(1..age)
      |> on_failure(fn _ -> "failed to count up to the user's age, (too old ?)" end)
    end)
  end

  def query_thinking do
    prompt("Wow, that's a lot ! Do you think so too ? ")
    |> on_failure(fn _ -> "failed to get an answer from the user" end)
  end

  def analyse(answer) do
    case String.trim(answer) do
      x when x in ["y", "Y", "yes", "Yes", "YES"] -> {{:success, "user thinks like me"}, []}
      x when x in ["n", "N", "no", "No", "NO"] -> {{:failure, "user didn't agree with me"}, []}
      _ -> {{:failure, "user didn't give a proper answer"}, []}
    end
  end

  def on_failure({{:failure, x}, rbs}, f), do: {{:failure, f.(x)}, rbs}
  def on_failure({{:success, _}, _} = mx, _), do: mx

  def bind({{:failure, _}, _} = mmx, _f), do: mmx
  def bind({{:success, x}, rbs}, f) do
    {my, rb2s} = f.(x)
    {my, rb2s ++ rbs}
  end

  def script1 do
    ask_name()
    |> bind(&greet/1)
    |> bind(fn _ -> ask_age() end)
    |> bind(fn bin ->
      case parse_age(bin) do
        {:error, _} -> {{:failure, "failed to get a proper age"}, []}
        {:ok, age} -> {{:success, age}, []}
      end
    end)
    |> bind(&count_up/1)
    |> bind(fn _ -> query_thinking() end)
    |> bind(&analyse/1)
    |> case do
      {{:success, msg}, _} -> msg
      {{:failure, msg}, rbs} ->
        _ = Enum.each(rbs, fn f -> Process.sleep(50) ; f.() end)
        msg
    end
  end

  # Haskell like
  def script2 do
    require Monad
    Monad.compute Rollback do
      name <- ask_name()
      greet(name)
      bin <- ask_age()
      age <- case parse_age(bin) do
        {:error, _} -> {{:failure, "failed to get a proper age"}, []}
        {:ok, age} -> {{:success, age}, []}
      end
      count_up(age)
      answer <- query_thinking()
      analyse(answer)
    end
    |> case do
      {{:success, msg}, _} -> msg
      {{:failure, msg}, rbs} ->
        _ = Enum.each(rbs, fn f -> Process.sleep(50) ; f.() end)
        msg
    end
  end
end
