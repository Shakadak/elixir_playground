defmodule Num do
  require Class

  Class.mk :from_int, 1

  Class.mk :add, 2

  def sum(xs, dict), do: List.foldr(xs, from_int(0, dict), &add(&1, &2, dict))
end

defmodule Num.Int do
  def from_int(x), do: x
  def add(x, y), do: x + y
end

defmodule Num.Bool do
  def from_int(0), do: false
  def from_int(_), do: true

  def add(true, _), do: true
  def add(false, x), do: x
end
