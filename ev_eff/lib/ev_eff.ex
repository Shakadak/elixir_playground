defmodule EvEff do
  @moduledoc """
  Documentation for `EvEff`.
  """

  import Bind
  import Eff

  import Reader
  import Exn
  import State

  @doc """
  Hello world.

  ## Examples

      iex> EvEff.hello()
      :world

  """
  def hello do
    :world
  end

  def greet do
    m Eff do
      s <- perform ask(), {}
      pure "hello " <> s
    end
  end

  def helloWorld do
    reader(greet())
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
end
