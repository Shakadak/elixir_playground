defmodule Eq do
  require Class

  Class.mk :eq, 2
end

defmodule Eq.Bool do
  def eq, do: fn
    (true, true) -> true
    (false, false) -> true
    (_, _) -> false
  end
end

defmodule Eq.Int do
  def eq, do: fn (x, y) -> x == y end
end
