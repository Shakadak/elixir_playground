defmodule FunList do
  import Type
  data fun_list(a, b, t) = done(t) | more(a, fun_list(a, b, (b -> t)))

  import Either

  # out :: FunList a b t → t + (a, FunList a b (b → t))
  # out (Done t) = Left t
  # out (More x l) = Right (x, l)
  def out(done(t)), do: left(t)
  def out(more(x, l)), do: right({x, l})

  # inn :: t + (a, FunList a b (b → t)) → FunList a b t
  # inn (Left t) = Done t
  # inn (Right (x, l)) = More x l
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

  Applicative.defaults(FunList)

  def pure(t), do: done(t)
  def ap(done(f), l_), do: Functor.FunList.map(f, l_)
  def ap(more(x, l), l_), do: more(x, Functor.FunList.map(curry(flip/3), l) |> ap(l_))

  def flip(f, x, y), do: f.(y, x)
end
