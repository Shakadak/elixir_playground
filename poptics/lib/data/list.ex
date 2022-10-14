defmodule Functor.List do
  def map(f, s), do: :lists.map(f, s)
end

defmodule Applicative.List do
  require Applicative

  Applicative.defaults(FunList)

  def pure(x), do: [x]
  def ap(fs, xs), do: for f <- fs, x <- xs, do: f.(x)
  def liftA2(fs, xs, ys), do: for f <- fs, x <- xs, y <- ys, do: f.(x, y)
end
