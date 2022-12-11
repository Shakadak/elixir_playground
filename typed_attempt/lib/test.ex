defmodule Test do
  use TypedAttempt

  typ now :: (-> io(time()))
  foreign import Kernel.+ :: (int(), int() -> int())

  typ sub :: (int(), int() -> int())
  unsafe det sub(x, y), do: x - y

  typ add :: (int(), int() -> int())
  det add(x, y),
    do: x + y

  typ plus1 :: (int() -> int())
  det plus1(x) do
    x + 1
  end

  typ add3 :: (int(), int(), int() -> int())
  det add3(x, y, z),
    do: x + y + z

  typ add_plus1 :: (int(), int() -> int())
  det add_plus1(x, y) do
    z = add(x, y)
    plus1(z)
  end

  typ one :: (() -> int())
  det one, do: {1, 1}

  typ sum :: (list(int()) -> int())
end
