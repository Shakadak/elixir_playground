defmodule Data.List do
  def head([x | _]) do x end
  def head([]) do raise("head: empty list") end

  def cons(x, xs) do [x | xs] end

  def snoc(xs, x) do [x | xs] end

  def uncons([]) do :none end
  def uncons([x | xs]) do {:some, {x, xs}} end

  def tail([_ | xs]) do xs end
  def tail([]) do raise("tail: empty list") end

  def last([x]) do x end
  def last([_ | xs]) do last(xs) end
  def last([]) do raise("last: empty list") end

  def init([_]) do [] end
  def init([x | xs]) do [x | init(xs)] end
  def init([]) do raise("init: empty list") end

  def null?([]) do true end
  def null?([_ | _]) do false end

  def product(xs) do Enum.reduce(xs, 1, &Kernel.*/2) end

  def foldr1([x | xs], f) do List.foldr(xs, x, f) end

  def scanr([], acc, _) do [acc] end
  def scanr([x | xs], acc, f) do
    qs = [q | _] = scanr(xs, acc, f)
    [f.(x, q) | qs]
  end

  def inits(xs) do List.foldr(xs, [[]], fn x, ys -> [[] | Enum.map(ys, fn y -> [x | y] end)] end) end
end
