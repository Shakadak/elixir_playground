defmodule TypeclassopediaAgain do
  @moduledoc """
  Documentation for `TypeclassopediaAgain`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TypeclassopediaAgain.hello()
      :world

  """
  def hello do
    :world
  end
end

require Functor

Functor.definstance Functor.List do
  defcurried map(f, ta) when is_list(ta) and is_function(f), do: :lists.map(f, ta)

  defcurried replace_with_left(x, ys), do: :lists.map(fn _ -> x end, ys)
end

Functor.definstance Functor.Maybe do
  defcurried map(_, :Nothing  ), do: :Nothing
  defcurried map(f, {:Just, x}), do: {:Just, f.(x)}
end

Functor.definstance Functor.Either do
  defcurried map(_, {:Left , _} = t), do: t
  defcurried map(f, {:Right, x}    ), do: {:Right, f.(x)}
end

Functor.definstance Functor.Function do
  defcurried map(f, g, x), do: f.(g.(x))
end

Functor.definstance Functor.Tuple2 do
  defcurried map(f, {e, x}), do: {e, f.(x)}
end

Functor.definstance Functor.ITree do
  defcurried leaf(f), do: {:Leaf, f}   # Leaf (Int -> a)
  defcurried node(xs), do: {:Node, xs} # Node [Itree a]

  defcurried map(f, {:Leaf, g} ), do: {:Leaf, fn x -> f.(g.(x)) end}
  defcurried map(f, {:Node, xs}), do: {:Node, :lists.map(map(f), xs)}

  # import Bask
  # itree = open Functor.ITree, do: node([node([leaf(fn x -> -x end)]), leaf(fn x -> 2 * x end)])
  # d = Functor.ITree.map(&to_string/1, itree)
  # iex(22)> get_in(d, [elem(1), at(1), elem(1)]).(3)
  # "6"
  # iex(23)> get_in(d, [elem(1), at(0), elem(1), at(0), elem(1)]).(3)
  # "-3"
end

require Applicative

Applicative.definstance Applicative.Maybe, Functor.Maybe do
  defcurried pure(x), do: {:Just, x}

  defcurried {:Just, f} <~> {:Just, x}, do: {:Just, f.(x)}
  defcurried _          <~> _         , do: :Nothing

  defcurried liftA2(f, {:Just, x}, {:Just, y}) when is_function(f, 2), do: {:Just, f.(x, y)}
  defcurried liftA2(f, {:Just, x}, {:Just, y}) when is_function(f, 1), do: {:Just, f.(x).(y)}
  defcurried liftA2(_, _         , _         )                       , do: :Nothing

  defcurried rightA({:Just, _}, ty), do: ty
  defcurried rightA(:Nothing  , _ ), do: :Nothing
end

Applicative.definstance Applicative.List, Functor.List do
  defcurried pure(x), do: [x]

  defcurried tf <~> tx, do: for f <- tf, x <- tx, do: f.(x)

  defcurried liftA2(f, tx, ty) when is_function(f, 2), do: for x <- tx, y <- ty, do: f.(x, y)
  defcurried liftA2(f, tx, ty) when is_function(f, 1), do: for x <- tx, y <- ty, do: f.(x).(y)

  defcurried rightA(tx, ty), do: for _ <- tx, y <- ty, do: y
end

require Monad

Functor.definstance Functor.Identity do
  defcurried map(f, {x}), do: {f.(x)}
end

Applicative.definstance Applicative.Identity, Functor.Identity do
  defcurried pure(x), do: {x}

  defcurried {f} <~> {x}, do: {f.(x)}
end

Monad.definstance Monad.Identity, Applicative.Identity do
  defcurried bind({x}, f), do: f.(x)
end

Monad.definstance Monad.Maybe, Applicative.Maybe do
  defcurried bind({:Just, x}, f), do: f.(x)
  defcurried bind(:Nothing  , _), do: :Nothing
end

Applicative.definstance Applicative.Function, Functor.Function do
  defcurried pure(x), do: fn _ -> x end

  defcurried tf <~> tx, do: fn e -> tf.(e).(tx.(e)) end

  defcurried liftA2(q, f, g, e) when is_function(q, 2), do: q.(f.(e), g.(e))
  defcurried liftA2(q, f, g, e) when is_function(q, 1), do: q.(f.(e)).(g.(e))
end

Monad.definstance Monad.Function, Applicative.Function do
  defcurried bind(mx, f, e), do: f.(mx.(e)).(e)
end

require Category

Category.definstance Category.Function do
  defcurried id(x), do: x
  defcurried f .. g, do: fn x -> f.(g.(x)) end
  defcurried f >>> g, do: fn x -> g.(f.(x)) end
end

require Arrow

Arrow.definstance Arrow.Function, Category.Function do
  defcurried arr(f), do: f
  defcurried parallel(f, g, {x, y}), do: {f.(x), g.(y)}
end
