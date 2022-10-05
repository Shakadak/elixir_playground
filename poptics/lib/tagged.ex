defmodule Tagged do
  import Type

  data tagged(a, b) = tagged(b)
end

  # derive instance newtypeTagged :: Newtype (Tagged a b) _

  # derive instance eqTagged :: Eq b => Eq (Tagged a b)
  # instance eq1Tagged :: Eq1 (Tagged a) where
  #   eq1 = eq

  # derive instance ordTagged :: Ord b => Ord (Tagged a b)
  # instance ord1Tagged :: Ord1 (Tagged a) where
  #   compare1 = compare

  # derive instance functorTagged :: Functor (Tagged a)

defmodule Profunctor.Tagged do
  # instance taggedProfunctor :: Profunctor Tagged where
  #   dimap _ g (Tagged x) = Tagged (g x)

  import Tagged

  def dimap(_, g, tagged(x)), do: tagged(g.(x))
end

defmodule Cocartesian.Tagged do
  # instance taggedChoice :: Choice Tagged where
  #   left (Tagged x) = Tagged (Left x)
  #   right (Tagged x) = Tagged (Right x)

  import Tagged
  require Either

  def left(tagged(x)), do: tagged(Either.left(x))
  def right(tagged(x)), do: tagged(Either.right(x))
end

  # instance taggedCostrong :: Costrong Tagged where
  #   unfirst (Tagged (Tuple b _)) = Tagged b
  #   unsecond (Tagged (Tuple _ c)) = Tagged c
