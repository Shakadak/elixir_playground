defmodule Test do
  import TypedAttempt

  foreign Kernel.+ :: (int(), int() -> int())
  typ add :: (int(), int() -> int())
  det add(x, y), do: x + y
end
