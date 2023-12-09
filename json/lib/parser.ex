defmodule Parser do
  @type parser(input, output) :: (input -> [{input, output}])

  defstruct [parser: &__MODULE__.fail/1]

  defmacro parsed(i, o), do: {:some, {i, o}}
  defmacro failed, do: :none

  defmacro parser!(fun) do
    mk_parser_ast(fun)
  end

  defp mk_parser_ast(ast) do
    quote do %unquote(__MODULE__){parser: unquote(ast)} end
  end

  @doc false
  def fail(_), do: failed()

  defmacro delay!(parser) do
    fun =
      quote do
        _ = fn input ->
          unquote(__MODULE__).run_parser(unquote(parser), input)
        end
      end

    mk_parser_ast(fun)
  end

  def run_parser(parser!(parser), input) do
    parser.(input)
  end

  def zero, do: parser! &fail/1

  def map(parser, f) do
    parser! fn input ->
      run_parser(parser, input)
      |> case do
        parsed(i, o) -> parsed(i, f.(o))
        failed() -> failed()
      end
    end
  end

  def pure(x), do: parser! fn i -> parsed(i, x) end

  def ap(mf, mx) do
    mf |> thenM(fn f ->
      mx |> thenM(fn x ->
        pure f.(x)
      end)
    end)
  end

  def ap2(mf, mx, my) do
    for(
      f <- mf,
      x <- mx,
      y <- my,
      into: zero()
    ) do
      f.(x, y)
    end
  end

  def ap3(mf, mx, my, mz) do
    for(
      f <- mf,
      x <- mx,
      y <- my,
      z <- mz,
      into: zero()
    ) do
      f.(x, y, z)
    end
  end

  def liftA2(f, mx, my) do
    for(
      x <- mx,
      y <- my,
      into: zero()
    ) do
      f.(x, y)
    end

    # mx |> thenM(fn x ->
    #   my |> thenM(fn y ->
    #     pure f.(x, y)
    #   end)
    # end)
  end

  def liftA3(f, mx, my, mz) do
    for(
      x <- mx,
      y <- my,
      z <- mz,
      into: zero()
    ) do
      f.(x, y, z)
    end
  end

  def thenM(parser, k) do
    parser! fn input ->
      run_parser(parser, input)
      |> case do
        failed() -> failed()
        parsed(rest, out) -> run_parser(k.(out), rest)
      end
    end
  end

  def optional(parser) do
    parser! fn input ->
      run_parser(parser, input)
      |> case do
        parsed(rest, out) -> parsed(rest, {:some, out})
        failed() -> parsed(input, :none)
      end
    end
  end

  @doc "One or more"
  def some(parser) do
    liftA2(&[&1 | &2], parser, delay!(many(parser)))
    |> Json.dbg_("some")
  end

  @doc "Zero or more"
  def many(parser) do
    delay!(some(parser)) ||| pure([])
  end

  @doc """
  Functional version of the macro `delay!`, used as such
  ```elixir
  delay_(fn -> many(parser) end)
  ```
  """
  def delay_(cont) do
    parser! fn input ->
      run_parser(cont.(), input)
    end
  end

  @doc """
  Runs both parser, but discard the result from the left.
  """
  def skip(l, r) do
    # parser! fn input ->
    #   case run_parser(l, input) do
    #     parsed(i, _) -> run_parser(r, i)
    #     failed() -> failed()
    #   end
    # end

    for _ <- l, r <- r, into: zero(), do: r
  end

  @doc """
  Runs both parser, but discard the result from the right.
  """
  def keep(l, r) do
    parser! fn input ->
      run_parser(l, input)
      |> case do
        parsed(i, o) -> run_parser(r |> as(o), i)
        failed() -> failed()
      end
    end

    for l <- l, _ <- r, into: zero(), do: l
  end

  def first_of(parsers) do
    parser! fn input ->
      Enum.reduce_while(parsers, failed(), fn parser, failed() ->
        case run_parser(parser, input) do
          parsed(_, _) = x -> {:halt, x}
          failed() -> {:cont, failed()}
        end
      end)
    end
  end

  def l ||| r do
    parser! fn input ->
      case run_parser(l, input) do
        parsed(_, _) = x -> x
        failed() -> run_parser(r, input)
      end
    end
  end

  def as(parser, value) do
    parser |> map(fn _ -> value end)
  end

  def satisfy(p) do
    parser! fn
      <<c, rest::binary>> ->
        if p.(c) do
          parsed(rest, c)
        else
          failed()
        end

      _ -> failed()
    end
  end

  def surrounded_by(pm, ps) do
    ps |> skip(pm) |> keep(ps)
    for(
      _ <- ps,
      v <- pm,
      _ <- ps,
      into: zero()
    ) do
      v
    end
  end

  def separated_by(v, s) do
    liftA2(&[&1 | &2], v, many(skip(s, v)))
      ||| pure([])
  end

  def bracket(l, m, r) do
    l |> skip(m) |> keep(r)
    for(
      _ <- l,
      v <- m,
      _ <- r,
      into: zero()
    ) do
      v
    end
  end

  def inspect_fun(fun) do
    fun_info = :erlang.fun_info(fun)
    _ = IO.inspect(fun_info)
    case Keyword.fetch!(fun_info, :type) do
      :external -> IO.inspect(fun)
      :local ->
        case Keyword.fetch!(fun_info, :env) do
          {:env, [{_, _, _, _, _, abs}]} ->
            str = :erl_pp.expr({:fun, 1, {:clauses, abs}})
            _ = IO.puts(str)
            fun

          [f] when is_function(f) ->
            #inspect_fun(f)
            #fun
            IO.inspect(fun, label: "bad match in inspect_fun")

          [] ->
           IO.inspect(fun)

          xs when is_list(xs) ->
            IO.inspect(fun, label: "bad match in inspect_fun")
        end
    end
    fun
  end

end

defimpl Collectable, for: Parser do
  def into(%Parser{}) do
    collector = fn
      _, :halt ->
        raise "welp ¯\_(ツ)_/¯"

      parser, :done ->
        parser

      _p, {:cont, v} -> Parser.pure(v)
    end

    initial_acc = Parser.zero()

    {initial_acc, collector}
  end
end

defimpl Enumerable, for: Parser do
  import Parser

  def count(parser!(_)), do: {:error, __MODULE__}
  def member?(parser!(_), _value), do: {:error, __MODULE__}
  def slice(parser!(_)), do: {:error, __MODULE__}

  def reduce(parser!(_), {:halt, acc}, _fun) do
    raise("#{inspect(__MODULE__)}.reduce(parser, {:halt, acc}, _fun)")
    {:halted, acc}
  end
  def reduce(parser!(_) = mp, {:suspend, acc}, fun) do
    raise("#{inspect(__MODULE__)}.reduce(parser, {:suspend, acc}, _fun)")
    {:suspended, acc, &reduce(mp, &1, fun)}
  end

  def reduce(parser!(_) = mp, {:cont, acc}, f) do
    ret = Parser.thenM(mp, fn x ->
      {:cont, v} = f.(x, acc)
      v
    end)

    {:done, ret}
  end
end
