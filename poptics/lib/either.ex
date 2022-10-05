defmodule Either do
  import Type

  data either(a, b) = left(a) | right(b)

  def either(f, _, left(x)), do: f.(x)
  def either(_, g, right(y)), do: g.(y)

  def plus(f, g) do
    fn
      left(x) -> left(f.(x))
      right(y) -> right(g.(y))
    end
  end
end

defmodule Bimap.Either do
  import Either
  def lmap(f, left(x)), do: left(f.(x))
  def lmap(_, right(_) = e_x), do: e_x
end
