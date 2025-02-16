defmodule EvEff do
  @moduledoc """
  Documentation for `EvEff`.
  """

  use Eff

  import Reader
  import Exn
  import State
  import Amb
  import Parser

  def greet do
    m Eff do
      s <- perform ask(), {}
      pure "hello " <> s
    end
  end

  def helloWorld do
    reader("world", greet())
  end

  def run_hello do
    runEff(helloWorld())
  end

  def safeDiv(_, 0), do: perform(failure(), {})
  def safeDiv(x, y), do: pure(div(x, y))

  def invert do
    m Eff do
      b <- perform get(), {}
      perform put(), (not b)
      perform get(), {}
    end
  end

  def run_invert do
    runEff(state(true, invert()))
  end

  def xor do
    m Eff do
      x <- perform flip(), {}
      y <- perform flip(), {}
      Eff.pure((x and not y) or (not x and y))
    end
  end

  def run_xor do
    runEff(allResults(xor()))
  end

  def eager_parse do
    runEff(eager(parse(~c'1+2*3', expr())))
  end

  def all_parse do
    runEff(solutions(parse(~c'1+2*3', expr())))
  end
end
