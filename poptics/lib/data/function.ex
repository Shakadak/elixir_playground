defmodule Profunctor.Function do
  def dimap(f, g, h) do
    fn x -> g.(h.(f.(x))) end
  end
end

defmodule Cartesian.Function do
  def first(h), do: fn x -> Bag.cross(h, &Bag.id/1, x) end
  def second(h), do: fn x -> Bag.cross(&Bag.id/1, h, x) end
end

defmodule Cocartesian.Function do
  def left(h), do: Either.plus(h, &Bag.id/1)
  def right(h), do: Either.plus(&Bag.id/1, h)
end

defmodule Monoidal.Function do
  def par(f, g), do: &Bag.cross(f, g, &1)
  def empty, do: &Bag.id/1
end
