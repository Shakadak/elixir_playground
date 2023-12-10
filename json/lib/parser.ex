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
    for(
      h <- parser,
      t <- many(parser),
      into: zero()
    ) do
      [h | t]
    end
  end

  @doc "Zero or more"
  def many(parser) do
    delay!(some(parser)) ||| pure([])
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
    p = 
      for(
        h <- v,
        t <- many(for _ <- s, v <- v, into: zero(), do: v),
        into: zero()
      ) do
        [h | t]
      end

    p ||| pure([])
  end

  def bracket(l, m, r) do
    for(
      _ <- l,
      v <- m,
      _ <- r,
      into: zero()
    ) do
      v
    end
  end
end

defimpl Collectable, for: Parser do
  def into(%Parser{}) do
    collector = fn
      _, :halt -> raise "welp ¯\_(ツ)_/¯"
      parser, :done -> parser
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
