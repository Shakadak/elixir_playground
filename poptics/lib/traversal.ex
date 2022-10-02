defmodule Curry do
  defmacro curry(fun, arity) do
    args = Macro.generate_unique_arguments(arity, __MODULE__)
    application = quote do unquote(fun).(unquote_splicing(args)) end

    args
    |> Enum.reverse()
    |> Enum.reduce(application, fn arg, acc ->
      quote do
        fn unquote(arg) -> unquote(acc) end
      end
    end)
    #|> case do x -> _ = IO.puts("curry/2 ->\n#{Macro.to_string(x)}") ; x end
  end

  #defmacro curry({:/, _, [{{:., _, _} = fun, meta, _}, arity]}) do
  #  true = is_integer(arity)
  #  args = Macro.generate_unique_arguments(arity, __MODULE__)
  #  application = quote do unquote({fun, meta, args}) end

  #  args
  #  |> Enum.reverse()
  #  |> Enum.reduce(application, fn arg, acc ->
  #    quote do
  #      fn unquote(arg) -> unquote(acc) end
  #    end
  #  end)
  #  |> case do x -> _ = IO.puts("curry/1 ->\n#{Macro.to_string(x)}") ; x end
  #end

  defmacro curry({:/, _, [{fun, meta, _}, arity]}) do
    true = is_integer(arity)
    args = Macro.generate_unique_arguments(arity, __MODULE__)
    application = quote do unquote({fun, meta, args}) end

    args
    |> Enum.reverse()
    |> Enum.reduce(application, fn arg, acc ->
      quote do
        fn unquote(arg) -> unquote(acc) end
      end
    end)
    #|> case do x -> _ = IO.puts("curry/1 ->\n#{Macro.to_string(x)}") ; x end
  end
end

defmodule Either do
  import Type

  data either(a, b) = left(a) | right(b)

  def either(f, _, left(x)), do: left(f.(x))
  def either(_, g, right(y)), do: right(g.(y))

  def plus(f, g) do
    fn
      left(x) -> left(f.(x))
      right(y) -> right(g.(y))
    end
  end
end

defmodule FunList do
  import Type
  data fun_list(a, b, t) = done(t) | more(a, fun_list(a, b, (b -> t)))

  import Either

  def out(done(t)), do: left(t)
  def out(more(x, l)), do: right({x, l})

  def inn(left(t)), do: done(t)
  def inn(right({x, l})), do: more(x, l)

  def single(x), do: more(x, done(& &1))

  def fuse(done(t)), do: t
  def fuse(more(x, l)), do: fuse(l).(x)
end

defmodule Functor.FunList do
  import Curry
  import FunList

  def map(f, done(t)), do: done(f.(t))
  def map(f, more(x, l)), do: more(x, map(curry(compose/3).(f), l))

  def compose(f, g, x), do: f.(g.(x))
end

defmodule Applicative.FunList do
  import FunList
  import Curry

  require Applicative

  Applicative.defaults(Functor.FunList)

  def pure(t), do: done(t)
  def ap(done(f), l_), do: Functor.FunList.map(f, l_)
  def ap(more(x, l), l_), do: more(x, Functor.FunList.map(curry(flip/3), l) |> ap(l_))

  def flip(f, x, y), do: f.(y, x)
end

defmodule Tree do
  import Type
  data tree(a) = empty | node(tree(a), a, tree(a))

  require Applicative

  import Curry

  def inorder(mod, _m, empty()), do: Applicative.pure(empty(), mod)
  def inorder(mod, m, node(t, x, u)) do
    import Applicative
    pure(curry(node/3), mod)
    |> ap(inorder(mod, m, t), mod)
    |> ap(m.(x), mod)
    |> ap(inorder(mod, m, u), mod)
  end
end

defmodule Traversal do
  import Type
  record traversal(a, b, s, t) = traversal %{extract: (s -> fun_list(a, b, t))}

  def inorderC do
    traversal(fn x -> Tree.inorder(FunList, &FunList.single/1, x) end)
  end

  def traverse(k, {cocartesian, monoidal}) do
    require Cocartesian
    require Monoidal
    require Profunctor
    profunctor = Cocartesian.superclass(cocartesian)
    f = &FunList.out/1
    g = fn {:Suspended, k} ->
      FunList.inn(k.())
    end
    suspension = {:Suspended, fn ->
      Cocartesian.right(Monoidal.par(k, traverse(k, {cocartesian, monoidal}), monoidal), cocartesian)
    end}
    Profunctor.dimap(f, g, suspension, profunctor)
  end

  def traversalC2P(traversal(h), {_cartesian, cocartesian, monoidal}) do
    require Cocartesian
    require Profunctor
    profunctor = Cocartesian.superclass(cocartesian)

    fn k ->
      Profunctor.dimap(h, &FunList.fuse/1, traverse(k, {cocartesian, monoidal}), profunctor) end
  end

  def traversalP2C(l), do: l.(traversal(&FunList.single/1))

  # traverseOf :: Applicative f => TraversalP a b s t -> (a -> f b) -> s -> f t
  def traverseOf(p, f, s) do
    import UpStar

    p.(up_star(f)).unUpStar.(s)
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
