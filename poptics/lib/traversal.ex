defmodule Traversal do
  import Type
  record traversal(a, b, s, t) = traversal %{extract: (s -> fun_list(a, b, t))}

  def inorderC do
    traversal(fn x -> Tree.inorder(FunList, &FunList.single/1, x) end)
  end

  # traverse : (Cocartesian p, Monoidal p) => p a b -> p (FunList a c t) (FunList b c t)
  # traverse k = dimap out inn (right (par k (traverse k)))
  # right : p a b -> p (c + a) (c + b)
  # par : p a b -> p c d -> p {a, c} {b, d}
  def traverse(k, type) do
    dict = Profunctor.Lazy.mk(type)
    traverse_go(k, type, dict)
  end

  # k : p a b
  # traverse k : (Cocartesian p, Monoidal p) => p (FunList a c t) (FunList b c t)
  # right : p a b -> p (c + a) (c + b)
  # par : p a b -> p (FunList a c t) (FunList b c t) -> p {a, (FunList a c t)} {b, (FunList b c t)}
  # \y -> par y (traverse k) : p a b -> p {a, (FunList a c t)} {b, (FunList b c t)}
  # par k (traverse k) : p {a, (FunList a c t)} {b, (FunList b c t)}
  # right (par k (traverse k)) : p (c + {a, (FunList a d t)}) (c + {b, (FunList b d t)})
  #
  # dimap : ((FunList a b t) -> (t + (a, FunList a b (b -> t)))) -> ((t + (a, FunList a b (b -> t))) -> (FunList a b t)) -> p a (t + (a, FunList a b (b -> t))) -> p (t + (a, FunList a b (b -> t))) (FunList a b t)
  #
  # dimap out inn : p a (t + (a, FunList a b (b -> t))) -> p (t + (a, FunList a b (b -> t))) (FunList a b t)
  #
  # dimap : ((a') -> (a)) -> ((b) -> (b')) -> p (a) (b) -> p (a') (b')
  # out :: FunList a b t -> c + (a, FunList a b (b -> c))
  # inn :: t + (a, FunList a b (b -> t)) -> FunList a b t
  #
  # dimap out : ((b) -> (b')) -> p (t + (a, FunList a b (b -> t))) (b) -> p (FunList a b t) (b')
  # dimap out inn : p (t + (a, FunList a b (b -> t))) (t + (a', FunList a' b (b -> t))) -> p (FunList a b t) (FunList a b t)
  def traverse_go(k, type, dict) do
    import Lazy

    require Cocartesian
    require Monoidal
    require Profunctor

    out = &FunList.out/1
    inn = &FunList.inn/1
    suspension = 
      delay(Cocartesian.right(Monoidal.par(k, fn x -> traverse_go(k, type, dict).(x) end, type), type))

    Profunctor.dimap(out, inn, suspension, dict)
  end

  def traversalC2P(traversal(h), type) do
    require Cocartesian
    require Profunctor

    fn k ->
      Profunctor.dimap(h, &FunList.fuse/1, traverse(k, type), type)
    end
  end

  def traversalP2C(l), do: l.(Traversal).(traversal(&FunList.single/1))

  # traverseOf :: Applicative f => TraversalP a b s t -> (a -> f b) -> s -> f t
  def traverseOf(p, f, s, applicative) do
    import UpStar
    cartesian = Cartesian.UpStar.mk(applicative)
    cocartesian = Cocartesian.UpStar.mk(applicative)
    monoidal = Monoidal.UpStar.mk(applicative)

    dict = Map.new(Enum.concat([cartesian, cocartesian, monoidal]))

    p.(dict).(up_star(f)).unUpStar.(s)
  end

  # inorderP :: TraversalP a b (Tree a) (Tree b)
  def inorderP(type) do
    traversalC2P(inorderC(), type)
  end
end

defmodule Profunctor.Traversal do
  import Traversal

  def dimap(f, g, traversal(h)) do
    traversal(&Functor.FunList.map(g, h.(f.(&1))))
  end
end

defmodule Cartesian.Traversal do
  import Traversal

  def first(traversal(h)), do: traversal(fn {s, c} -> Functor.FunList.map(&{&1, c}, h.(s)) end)
  def second(traversal(h)), do: traversal(fn {c, s} -> Functor.FunList.map(&{c, &1}, h.(s)) end)
end

defmodule Cocartesian.Traversal do
  import Traversal
  require Either
  require FunList

  def left(traversal(h)) do
    left = &Either.left/1

    on_left = &Functor.FunList.map(left, h.(&1))
    on_right = &FunList.done(Either.right(&1))

    traversal(&Either.either(on_left, on_right, &1))
  end

  def right(traversal(h)) do
    right = &Either.right/1

    on_left = &FunList.done(Either.left(&1))
    on_right = &Functor.FunList.map(right, h.(&1))

    traversal(&Either.either(on_left, on_right, &1))
  end
end

defmodule Monoidal.Traversal do
  import Traversal

  def par(traversal(h), traversal(k)), do: traversal(&Bag.pair(h, k, &1, Applicative.FunList))
  def empty, do: traversal(&Applicative.FunList.pure/1)
end
