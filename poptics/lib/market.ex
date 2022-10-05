defmodule Market do
  import Type

  data market(a, b, s, t) = market((b -> t), (s -> either(t, a)))

end

defmodule Functor.Market do
  # instance functorMarket :: Functor (Market a b s) where
  #   map f (Market a b) = Market (f <<< a) (lmap f <<< b)

  import Market

  def map(f, market(a, b)) do
    market(&f.(a.(&1)), &Bimap.Either.lmap(f, b.(&1)))
  end
end

defmodule Profunctor.Market do
  # instance profunctorMarket :: Profunctor (Market a b) where
  #   dimap f g (Market a b) = Market (g <<< a) (lmap g <<< b <<< f)

  import Market

  def dimap(f, g, market(a, b)) do
    market(&g.(a.(&1)), &Bimap.Either.lmap(g, b.(f.(&1))))
  end
end

defmodule Cocartesian.Market do
  # instance choiceMarket :: Choice (Market a b) where
  #   left (Market x y) =
  #     Market (Left <<< x) (either (lmap Left <<< y) (Left <<< Right))
  #   right (Market x y) =
  #     Market (Right <<< x) (either (Left <<< Left) (lmap Right <<< y))

  import Market
  require Either
  require Cocartesian

  def left(market(x, y)) do
    on_left = fn t -> Bimap.Either.lmap(&Either.left/1, y.(t)) end
    on_right = &Either.left(Either.right(&1))
    market(&Either.left(x.(&1)), &Either.either(on_left, on_right, &1))
  end

  def right(market(x, y)) do
    on_left = &Either.left(Either.left(&1))
    on_right = fn a -> Bimap.Either.lmap(&Either.right/1, y.(a)) end
    market(&Either.right(x.(&1)), &Either.either(on_left, on_right, &1))
  end
end
