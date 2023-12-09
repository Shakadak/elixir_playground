defmodule Json do
  import Parser, only: [
    parser!: 1,

    parsed: 2,
    failed: 0,

    as: 2,
    |||: 2,
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

  def char(c) when is_integer(c), do: Parser.satisfy & &1 == c

  def digit do
    Parser.satisfy(& &1 in ?0..?9)
    |> Parser.map(&digit_to_int/1)
  end

  def digit_to_int(char), do: char - ?0

  def string(str) do
    str_size = byte_size(str)
    parser! fn
      <<^str::binary-size(str_size), rest::binary>> -> parsed(rest, str)
      _ -> failed()
    end
  end

  def null do
    parser! fn
      <<"null", rest::binary>> -> parsed(rest, nil)
      _ -> failed()
    end
  end

  def jNull do
    string("null") |> as(nil)
  end

  def bool do
    parser! fn
      <<"true", rest::binary>> -> parsed(rest, true)
      <<"false", rest::binary>> -> parsed(rest, false)
      _ -> failed()
    end
  end

  def jBool do
    string("true")  |> as(true) ||| string("false") |> as(false)
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

    string("\\\"") |> as("\"")
      ||| string("\\\\") |> as("\\")
      ||| string("\\n")  |> as("\n")
      ||| string("\\r")  |> as("\r")
      ||| string("\\t")  |> as("\t")
      ||| string("\\b")  |> as("\b")
      ||| string("\\f")  |> as("\f")
      # TODO: unicode_char
      ||| Parser.satisfy(& &1 not in cs)
  end

  def jString do
    Parser.bracket(char(?"), jStringb(), char(?"))
  end

  def jStringb do
    Parser.optional(json_char())
    |> Parser.thenM(fn optFirst ->
      optFirst
      |> case do
        :none -> Parser.pure("")
        {:some, str} -> jStringb() |> Parser.map(&<<str::utf8, &1::binary>>)
      end
    end)

    for(
      optFirst <- Parser.optional(json_char()),
      x <- case optFirst do
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
    digit19 =
      Parser.satisfy(& &1 in ?1..?9)
      |> Parser.map(&digit_to_int/1)

    p = Parser.liftA2(&digits_to_number(10, 0, [&1 | &2]), digit19, digits())
      ||| digit()

    p |> dbg_("jUInt")
  end

  def digits, do: Parser.some(digit())

  def jIntb do
    Parser.liftA2(&signInt/2, Parser.optional(char(?-)), jUInt())
  end

  def signInt({:some, ?-}, i), do: -i
  def signInt(_,      i),      do: i

  def jFrac, do: char(?.) |> Parser.skip(digits()) |> Parser.map(&digits_to_number(10, 0, &1))

  def jExp do
    sign = Parser.optional(char(?+) ||| char(?-))

    (char(?e) ||| char(?E))
    |> Parser.skip(Parser.liftA2(&signInt/2, sign, jUInt()))
  end

  def jInt do 
    jIntb() |> Parser.map(&{&1, [], 0})
  end

  def jIntExp do
    Parser.liftA2(&{&1, [], &2}, jIntb(), jExp())
    |> dbg_("jIntExp")
  end

  def jIntFrac do
    Parser.liftA2(&{&1, &2, 0}, jIntb(), jFrac())
  end

  def jIntFracExp do
    Parser.liftA3(&{&1, &2, &3}, jIntb(), jFrac(), jExp())
    |> dbg_("jIntFracExp")
  end

  def jNumber do
    parser = jIntFracExp() ||| jIntFrac() ||| jIntExp() ||| jInt()

    parser
    |> Parser.map(fn 
      {n, [], 0} -> n
      {n, [], exp} -> n * 10 ** exp
      {n, frac, 0} -> String.to_float("#{n}.#{frac}")
      {n, frac, exp} -> String.to_float("#{n}.#{frac}e#{exp}")
    end)
    |> dbg_("jNumber")
  end

  def spaces do
    Parser.many(char(?\s) ||| char(?\n) ||| char(?\r) ||| char(?\t))
  end

  def jArray do
    value = 
      Parser.delay!(jValue())
      |> Parser.surrounded_by(spaces())

    values =
      value
      |> Parser.separated_by(char(?,))

    Parser.bracket(char(?[), values, char(?]))
  end

  def jValue do
    p =
      jNull()
        ||| jBool()
        ||| jString()
        ||| jNumber()
        ||| jArray()
        ||| jObject()

    p |> Parser.surrounded_by(spaces())
  end

  def jObject do
    key =
      jString()
      |> Parser.surrounded_by(spaces())
      |> dbg_("key of jObject")

    and_value = char(?:) |> Parser.skip(Parser.delay!(jValue()))

    pair =
      (&{&1, &2})
      |> Parser.liftA2(key, and_value)

    pairs =
      pair
      |> Parser.surrounded_by(spaces())
      |> Parser.separated_by(char(?,))

    Parser.bracket(char(?{), pairs, char(?}))
    |> Parser.map(&Map.new/1)
  end

  def dbg_(parser, label) do
    parser! fn input ->
      _ = IO.inspect(input, label: "#{label} | input")
      Parser.run_parser(parser, input)
      |> IO.inspect(label: "#{label} | result")
    end
    parser
  end
end
