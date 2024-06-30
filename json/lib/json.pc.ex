defmodule Json.ParserCombinator do
  #def deserialize(bin) do
  #  case bin do
  #    "null" -> nil
  #    "true" -> "true"
  #    "false" -> "false"
  #    <<?", rest::binary>> -> parse
  #  end
  #end

  @type parser(input, output) :: (input -> {:some, {input, output}})

  defmacro parsed(i, o), do: {:some, {i, o}}
  defmacro failed, do: :none

  defmacro delay!(parser) do
    quote do
      _ = fn input ->
        run_parser(unquote(parser), input)
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
    first_of [
      delay!(some(parser)),
      pure([]),
    ]
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

  def surrounded_by(ps, pm) do
    ps |> skip(pm) |> keep(ps)
  end

  def char(c) when is_integer(c), do: satisfy & &1 == c

  def digit do
    satisfy(& &1 in ?0..?9) |> map(&digit_to_int/1)
  end

  def digit_to_int(char), do: char - ?0

  def string(str) do
    str_size = byte_size(str)
    _ = fn
      <<^str::binary-size(str_size), rest::binary>> -> parsed(rest, str)
      _ -> failed()
    end
  end

  def null do
    _ = fn
      <<"null", rest::binary>> -> parsed(rest, nil)
      _ -> failed()
    end
  end

  def null2 do
    string("null") |> as(nil)
  end

  def bool do
    _ = fn
      <<"true", rest::binary>> -> parsed(rest, true)
      <<"false", rest::binary>> -> parsed(rest, false)
      _ -> failed()
    end
  end

  def bool2 do
    first_of [
      string("true")  |> as(true),
      string("false") |> as(false),
    ]
  end

  def json_char do
    cs = [
      ?",
      ?\\,
      ?\n,
      ?\r,
      ?\t,
      ?\b,
      ?\f,
    ]

    first_of([
      string("\\\"") |> map(fn _ -> IO.puts("got a \\\"") ; "\"" end),
      string("\\\\") |> as("\\"),
      string("\\n")  |> as("\n"),
      string("\\r")  |> as("\r"),
      string("\\t")  |> as("\t"),
      string("\\b")  |> as("\b"),
      string("\\f")  |> as("\f"),
      # TODO: unicode_char
      satisfy(& &1 not in cs),
    ])
  end

  def jString do
    char(?") |> skip(jStringb())
  end

  def jStringb do
    optional(json_char())
    |> thenM(fn optFirst ->
      optFirst |> IO.inspect(label: "jstringb optFirst")
      |> case do
        :none -> pure("") |> keep(char(?"))
        {:some, str} -> jStringb() |> map(&<<str::utf8, &1::binary>>)
      end
    end)
  end

  def digits_to_number(base, zero, ds) do
    Enum.reduce(ds, zero, fn d, acc -> acc * base + d end)
  end

  def jUInt do
    digit19 = satisfy(& &1 in ?1..?9) |> map(&digit_to_int/1)

    first_of [
      liftA2(&digits_to_number(10, 0, [&1 | &2]), digit19, digits()),
      digit(),
    ]
  end

  def digits, do: some(digit())

  def jIntb do
    liftA2(&signInt/2, optional(char(?-)), jUInt())
  end

  def signInt({:some, ?-}, i), do: -i
  def signInt(_,      i),      do: i

  def jFrac, do: char(?.) |> skip(digits()) |> map(&digits_to_number(10, 0, &1))

  def jExp do
    sign = optional(first_of [char(?+), char(?-)])

    first_of([char(?e), char(?E)])
    |> skip(liftA2(&signInt/2, sign, jUInt()))
  end

  def jInt do 
    jIntb() |> map(&{&1, [], 0})
  end

  def jIntExp do
    liftA2(&{&1, [], &2}, jIntb(), jExp())
  end

  def jIntFrac do
    liftA2(&{&1, &2, 0}, jIntb(), jFrac())
  end

  def jIntFracExp do
    liftA3(&{&1, &2, &3}, jIntb(), jFrac(), jExp())
  end

  def jNumber do
    first_of([
      jIntFracExp(),
      jIntFrac(),
      jIntExp(),
      jInt(),
    ])
    |> map(fn 
      {n, [], 0} -> n
      {n, [], exp} -> n * 10 ** exp
      {n, frac, 0} -> String.to_float("#{n}.#{frac}")
      {n, frac, exp} -> String.to_float("#{n}.#{frac}e#{exp}")
    end)
  end
end
