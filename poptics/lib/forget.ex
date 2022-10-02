defmodule Forget do
  import Type

  data forget(r, a, b) = forget((a -> r))
end

defmodule Profunctor.Forget do
  import Forget
  def dimap(f, _, forget(z)), do: forget(&z.(f.(&1)))
end

defmodule Cartesian.Forget do
  import Forget

  require Cartesian

  Cartesian.defaults(Profunctor.Forget)

  def first(forget(z)), do: forget(&z.(Bag.fst(&1)))
  def second(forget(z)), do: forget(&z.(Bag.snd(&1)))
end
