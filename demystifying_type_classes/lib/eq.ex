defmodule Eq do
  require Class

  Class.mk :eq, 2
end

defmodule Eq.Bool do
  def eq(true, true), do: true
  def eq(false, false), do: true
  def eq(_, _), do: false
end

defmodule Eq.Int do
  def eq(x, y), do: x == y
end
