defmodule Num do
  require Class

  Class.mk :from_int, 1

  Class.mk :add, 2

  def sum(xs, dict), do: List.foldr(xs, from_int(0, dict), &add(&1, &2, dict))
end

defmodule Num.Int do
  def from_int, do: fn (x) -> x end
  def add, do: fn (x, y) -> x + y end
end

defmodule Num.Bool do
  def from_int, do: fn
    (0) -> false
    (_) -> true
  end

  def add, do: fn
    (true, _) -> true
    (false, x) -> x
  end
end
