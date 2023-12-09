defmodule Parser do
  @type parser(input, output) :: (input -> {:some, {input, output}})

  defmacro parsed(i, o), do: {:some, {i, o}}
  defmacro failed, do: :none

  defmacro delay!(parser) do
    quote do
      _ = fn input ->
        unquote(__MODULE__).run_parser(unquote(parser), input)
      end
    end
  end

  def run_parser(parser, input) do
    parser.(input)
  end

  def map(parser, f) do
    _ = fn input ->
      case run_parser(parser, input) do
        parsed(i, o) -> parsed(i, f.(o))
        failed() -> failed()
      end
    end
  end

  def pure(x), do: fn i -> parsed(i, x) end

  def ap(mf, mx) do
    mf |> thenM(fn f ->
      mx |> thenM(fn x ->
        pure f.(x)
      end)
    end)
  end

  def ap2(mf, mx, my) do
    mf |> thenM(fn f ->
      mx |> thenM(fn x ->
        my |> thenM(fn y ->
          pure f.(x, y)
        end)
      end)
    end)
  end

  def ap3(mf, mx, my, mz) do
    mf |> thenM(fn f ->
      mx |> thenM(fn x ->
        my |> thenM(fn y ->
          mz |> thenM(fn z ->
            pure f.(x, y, z)
          end)
        end)
      end)
    end)
  end

  def liftA2(f, mx, my) do
    mx |> thenM(fn x ->
      my |> thenM(fn y ->
        pure f.(x, y)
      end)
    end)
  end

  def liftA3(f, mx, my, mz) do
    mx |> thenM(fn x ->
      my |> thenM(fn y ->
        mz |> thenM(fn z ->
          pure f.(x, y, z)
        end)
      end)
    end)
  end

  def thenM(parser, k) do
    _ = fn input ->
      run_parser(parser, input)
      |> case do
        failed() -> failed()
        parsed(rest, out) -> run_parser(k.(out), rest)
      end
    end
  end

  def optional(parser) do
    _ = fn input ->
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
  end

  @doc "Zero or more"
  def many(parser) do
    Json.dbg_(delay!(some(parser)) ||| pure([]), "many")
  end

  @doc """
  Functional version of the macro `delay!`, used as such
  ```elixir
  delay(fn k -> k.(many(parser)) end)
  ```
  """
  def delay(cont) do
    _ = fn input ->
      cont.(&run_parser(&1, input))
    end
  end

  @doc """
  Runs both parser, but discard the result from the left.
  """
  def skip(l, r) do
    _ = fn input ->
      case run_parser(l, input) do
        parsed(i, _) -> run_parser(r, i)
        failed() -> failed()
      end
    end
  end

  @doc """
  Runs both parser, but discard the result from the right.
  """
  def keep(l, r) do
    _ = fn input ->
      run_parser(l, input)
      |> case do
        parsed(i, o) -> run_parser(r |> as(o), i)
        failed() -> failed()
      end
    end
  end

  def first_of(parsers) do
    _ = fn input ->
      Enum.reduce_while(parsers, failed(), fn parser, failed() ->
        case run_parser(parser, input) do
          parsed(_, _) = x -> {:halt, x}
          failed() -> {:cont, failed()}
        end
      end)
    end
  end

  def l ||| r do
    _ = fn input ->
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
    _ = fn
      <<c, rest::binary>> ->
        if p.(c) do
          parsed(rest, c)
        else
          failed()
        end

      _ -> failed()
    end
  end

  def fail do
    _ = fn _input ->
      failed()
    end
  end

  def surrounded_by(pm, ps) do
    ps |> skip(pm) |> keep(ps)
    |> Json.dbg_("surrounded_by")
  end

  def separated_by(v, s) do
    liftA2(&[&1 | &2], v, many(skip(s, v)))
      ||| pure([])
  end

  def bracket(l, m, r) do
    l |> skip(m) |> keep(r)
  end
end
