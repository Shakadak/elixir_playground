defmodule Json do
  import Parser,
    only: [
      parser!: 1,
      parsed: 2,
      failed: 0,
      as: 2,
      |||: 2
    ]

  require Parser

  def parseJSON(bin) do
    jValue()
    |> Parser.run_parser(bin)
    |> case do
      parsed("", j) -> {:some, j}
      _ -> :none
    end
  end

  def char(c) when is_integer(c), do: Parser.satisfy(&(&1 == c))

  def digit do
    Parser.satisfy(&(&1 in ?0..?9))
    |> Parser.map(&digit_to_int/1)
  end

  def digit_to_int(char), do: char - ?0

  def string(str) when is_binary(str) do
    str_size = byte_size(str)

    parser!(fn
      <<^str::binary-size(str_size), rest::binary>> -> parsed(rest, str)
      _ -> failed()
    end)
  end

  def jNull do
    string("null") |> as(nil)
  end

  def jBool do
    string("true") |> as(true) ||| string("false") |> as(false)
  end

  def json_char do
    cs = [
      ?",
      ?\\,
      ?\n,
      ?\r,
      ?\t,
      ?\b,
      ?\f
    ]

    # TODO: unicode_char
    string("\\\"") |> as("\"") |||
      string("\\\\") |> as("\\") |||
      string("\\n") |> as("\n") |||
      string("\\r") |> as("\r") |||
      string("\\t") |> as("\t") |||
      string("\\b") |> as("\b") |||
      string("\\f") |> as("\f") |||
      Parser.satisfy(&(&1 not in cs))
  end

  def jString do
    Parser.bracket(char(?"), jStringb(), char(?"))
  end

  def jStringb do
    for(
      optFirst <- Parser.optional(json_char()),
      x <-
        case optFirst do
          :none -> Parser.pure("")
          {:some, str} -> jStringb() |> Parser.map(&<<str::utf8, &1::binary>>)
        end,
      into: Parser.zero()
    ) do
      x
    end
  end

  def digits_to_number(base, zero, ds) do
    Enum.reduce(ds, zero, fn d, acc -> acc * base + d end)
  end

  def jUInt do
    digit19 = for d <- Parser.satisfy(&(&1 in ?1..?9)), into: Parser.zero(), do: digit_to_int(d)

    num =
      for(
        lead <- digit19,
        rest <- digits(),
        into: Parser.zero()
      ) do
        digits_to_number(10, 0, [lead | rest])
      end

    num ||| digit()
  end

  def digits, do: Parser.some(digit())

  def jIntb do
    for(
      maybe_sign <- Parser.optional(char(?-)),
      uint <- jUInt(),
      into: Parser.zero()
    ) do
      signInt(maybe_sign, uint)
    end
  end

  def signInt({:some, ?-}, i), do: -i
  def signInt(_, i), do: i

  def jFrac do
    for(
      _ <- char(?.),
      ds <- digits(),
      into: Parser.zero()
    ) do
      digits_to_number(10, 0, ds)
    end
  end

  def jExp do
    for(
      _ <- char(?e) ||| char(?E),
      maybe_sign <- Parser.optional(char(?+) ||| char(?-)),
      uint <- jUInt(),
      into: Parser.zero()
    ) do
      signInt(maybe_sign, uint)
    end
  end

  def jNumber do
    for(
      i <- jIntb(),
      f <- jFrac() ||| Parser.pure([]),
      e <- jExp() ||| Parser.pure(0),
      into: Parser.zero()
    ) do
      case {i, f, e} do
        {n, [], 0} -> n
        {n, [], exp} -> n * 10 ** exp
        {n, frac, 0} -> String.to_float("#{n}.#{frac}")
        {n, frac, exp} -> String.to_float("#{n}.#{frac}e#{exp}")
      end
    end
  end

  def spaces do
    Parser.many(char(?\s) ||| char(?\n) ||| char(?\r) ||| char(?\t))
  end

  def jArray do
    value = Parser.delay!(jValue()) |> Parser.surrounded_by(spaces())
    values = value |> Parser.separated_by(char(?,))
    Parser.bracket(char(?[), values, char(?]))
  end

  def jValue do
    p =
      jNull() |||
        jBool() |||
        jString() |||
        jNumber() |||
        jArray() |||
        jObject()

    p |> Parser.surrounded_by(spaces())
  end

  def jObject do
    pair =
      for(
        key <- jString() |> Parser.surrounded_by(spaces()),
        _ <- char(?:),
        value <- jValue(),
        into: Parser.zero()
      ) do
        {key, value}
      end

    pairs =
      pair
      |> Parser.surrounded_by(spaces())
      |> Parser.separated_by(char(?,))

    Parser.bracket(char(?{), pairs, char(?}))
    |> Parser.map(&Map.new/1)
  end

  def dbg_(parser, label) do
    parser!(fn input ->
      _ = IO.inspect(input, label: "#{label} | input")

      Parser.run_parser(parser, input)
      |> IO.inspect(label: "#{label} | result")
    end)

    parser
  end
end
