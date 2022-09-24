defmodule DemystifyingTypeClasses do
  @moduledoc """
  http://okmij.org/ftp/Computation/typeclass.html#dict
  """

  def test_print, do: Show.print(true, Show.Bool)

  def print_incr(x, {show, num}) do
    import Num
    Show.print(add(x, from_int(1, num), num), show)
  end

  def print_incr_int(x), do: print_incr(x, {Show.Int, Num.Int})

  def testls, do: (require Show ; Show.show([1, 2, 3], Show.List.mk(Show.Int)))

  def dot(xs, ys, dict) do
    import Mul
    {_, num} = mul_super(dict)
    Num.sum(Enum.map(Enum.zip(xs, ys), fn {x, y} -> mul(x, y, dict) end), num)
  end

  def test_dot, do: dot([1, 2, 3], [4, 5, 6], Mul.Int)

  def print_nested(show, 0, x), do: Show.print(x, show)
  def print_nested(show, n, x), do: print_nested(Show.List.mk(show), n - 1, List.duplicate(x, n))

  def test_nested do
    n = String.to_integer(String.trim(IO.gets("Enter nesting amount: ")))
    print_nested(Show.Int, n, 5)
  end
end
