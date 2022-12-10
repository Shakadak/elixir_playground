defmodule Test do
  use TypedAttempt

  typ now :: (-> io(time()))
  foreign import Kernel.+ :: (int(), int() -> int())
  typ add :: (int(), int() -> int())
  det add(x, y),
    do: x + y

  typ sub :: (int(), int() -> int())
  unsafe det sub(x, y), do: x - y

  typ sum :: (list(int()) -> int())
end
