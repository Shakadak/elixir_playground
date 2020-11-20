
defmodule Typeclassopedia do
  @moduledoc """
  Documentation for `Typeclassopedia`.
  """

  # FUNCTORS

  def functor_list, do: Functor.define(map: fn x, f -> :lists.map(f, x) end)

  def functor_maybe, do: Functor.define(map: fn
    :Nothing  , _   -> :Nothing
    {:Just, x}, f   -> {:Just, f.(x)}
  end)

  def functor_either, do: Functor.define(map: fn
    {:Left, _} , _ = t_a -> t_a
    {:Right, x}, f       -> {:Right, f.(x)}
  end)

  # (a -> b) -> f a -> f b = (a -> b) -> (e -> a) -> (e -> b)
  # f a = (e -> a) # a -> b = (e -> a) -> (e -> b)
  def functor_function_out, do: Functor.define(map: fn fa, f -> fn x -> f.(fa.(x)) end end)

  def functor_tuple2, do: Functor.define(map: fn {e, x}, f -> {e, f.(x)} end)

  def functor_pair, do: Functor.define(map: fn {x, y}, f -> {f.(x), f.(y)} end)

  def itree_leaf(f), do: {:Leaf, f}   # Leaf (Int -> a)
  def itree_node(xs), do: {:Node, xs} # Node [Itree a]

  def functor_itree do
    
    recf = fn recf -> fn
      {:Leaf, g} , f -> {:Leaf, fn x -> f.(g.(x)) end}
      {:Node, xs}, f -> {:Node, :lists.map(fn x -> recf.(recf).(f, x) end, xs)}
    end end

    Functor.define(map: recf.(recf))
  end

  # APPLICATIVES

  def applicative_maybe, do: Applicative.define(
    functor: functor_maybe(),
    pure: fn x -> {:Just, x} end,
    apA: fn
      {:Just, f}, {:Just, x} -> {:Just, f.(x)}
      _         , _          -> :Nothing
    end
  )

  def applicative_ziplist, do: Applicative.define(
    functor: functor_list(),
    pure: fn x -> [x] end,
    apA: fn fs, xs -> :lists.zipwith(fn f, x -> f.(x) end, fs, xs) end
  )

  def applicative_list, do: Applicative.define(
    functor: functor_list(),
    pure: fn x -> [x] end,
    apA: fn fs, xs -> for f <- fs, x <- xs, do: f.(x) end,
    liftA2: fn f, xs, ys -> for x <- xs, y <- ys, do: f.(x, y) end
  )

  def sequenceAL(mx_s, applicative_dict), do: :lists.foldr(fn mx, m_xs -> applicative_dict.liftA2.(fn x, xs -> [x | xs] end, mx, m_xs) end, applicative_dict.pure.([]), mx_s)

  def monad_identity, do: Monad.define(
    applicative: Applicative.define(
      functor: Functor.define(
        map: fn {x}, f -> {f.(x)} end
      ),
      pure: fn x -> {x} end,
      apA: fn {f}, {x} -> {f.(x)} end
    ),
    bind: fn {x}, f -> f.(x) end
  )

  def monad_maybe, do: Monad.define(
    applicative: applicative_maybe(),
    bind: fn
      {:Just, x}, f -> f.(x)
      :Nothing, _ -> :Nothing
    end
    )

  def monad_list, do: Monad.define(
    applicative: applicative_list(),
    bind: fn xs, f -> Enum.flat_map(xs, f) end
  )

  def monad_function_out, do: Monad.define(
    applicative: Applicative.define(
      functor: functor_function_out(),
      pure: fn x -> fn _ -> x end end,
      apA: fn mf, mx -> fn e -> mf.(e).(mx.(e)) end end
    ),
    bind: fn mx, f -> fn e -> f.(mx.(e)).(e) end end
  )

  # when you have the type of combinators, and you know the type of what you want to implement,
  # seek to start from type you want to implement, and use combinators to transform it into something you want
  # for example, we want to implement map in term of bind and return
  # map : (a -> b) -> f a -> f b
  # bind : f a -> (a -> f b) -> fb
  # return : a -> f a
  # we can see that map and bind are pretty close in shape, so to use bind, we must swap
  # the argument of map
  # map f x = bind x f
  # but f doesn't fit
  # the input does, but not the output, so we have to change the output
  # return allows us to change b to f b
  # so we just have to create a new function that take the result from f and applies it to return
  # mf x = return (f x)
  # or with function composition
  # mf = return . f
  # so we have everything for our implementation
  # map f x = bind x (return . f)
  # or in elixir notation
  # def map(f, mx), do: bind(mx, fn x -> return(f.(x)) end)
  #
  # same stuff with join
  # join : m (m a) -> m a
  # bind : m a -> (a -> m b) -> m b
  # return : a -> m a
  # here return's type doesnt fit, it does the opposite of join
  # we can specialize its type to show it by replacing a by m a
  # return : m a -> m (m a)
  # so we can't use it unless we know of a combinator to reverse it, but I am not aware
  # we are then left with bind
  # we need to remove the function for the shape to match
  # supposing we have done it, applied bind type would look like this
  # bind _ g : m a -> m b
  # to to be the same type as join, we must have a = m b
  # bind _ g : m (m b) -> m b
  # so if we remove the application of our hypothetical function, and specialize the type of bind
  # bind : m (m b) -> (m b -> m b) -> mb
  # we can recognise the shape of the function needed, and the simplest function that would match is
  # id : a -> a
  # with a = m b
  # so we then get a definition of join
  # join x = bind x id
  # or in elixir notation
  # def join(mx), do bind(mx, fn x -> x end)

  ### Semigroup ###

  def semigroup_maybe(semigroup_a) do
    Semigroup.define(
      <>: fn
        :Nothing,   x          -> x
        x,          :Nothing   -> x
        {:Just, x}, {:Just, y} -> semigroup_a.concat.(x, y)
      end
    )
  end

  def semigroup_first do
    Semigroup.define(<>: fn
      {:First, :Nothing}, x -> x
      x,                    _ -> x
    end)
  end

  def semigroup_last do
    Semigroup.define(<>: fn
      x, {:Last, :Nothing} -> x
      _, x                 -> x
    end)
  end

  def semigroup_list do
    Semigroup.define(<>: &++/2)
  end

  def semigroup_sum do
    Semigroup.define(<>: &+/2)
  end

  def semigroup_product do
    Semigroup.define(<>: &*/2)
  end

  ### Monoid ###

  def monoid_list do
    Monoid.define(
      semigroup: semigroup_list(),
      mempty: [],
      mconcat: &Enum.concat/1
    )
  end

  def monoid_sum do
    Monoid.define(
      semigroup: semigroup_sum(),
      mempty: 0,
      mconcat: &Enum.sum/1
    )
  end

  def monoid_product do
    Monoid.define(
      semigroup: semigroup_product(),
      mempty: 1
    )
  end

  def monoid_any do
    Monoid.define(
      semigroup: Semigroup.define(<>: &or/2),
      mempty: false,
      mconcat: fn xs -> Enum.reduce_while(xs, false, fn x, acc -> if x or acc, do: {:halt, true}, else: {:cont, false} end) end
    )
  end

  def monoid_all do
    Monoid.define(
      semigroup: Semigroup.define(<>: &and/2),
      mempty: true,
      mconcat: fn xs -> Enum.reduce_while(xs, true, fn x, acc -> if x and acc, do: {:cont, true}, else: {:halt, false} end) end
    )
  end

  def monoid_maybe(semigroup_a) do
    Monoid.define(
      semigroup: semigroup_maybe(semigroup_a),
      mempty: :Nothing
    )
  end

  def monoid_first do
    Monoid.define(
      semigroup: semigroup_first(),
      mempty: {:First, :Nothing}
    )
  end

  def monoid_last do
    Monoid.define(
      semigroup: semigroup_last(),
      mempty: {:Last, :Nothing}
    )
  end

  def monoid_endo do
    Monoid.define(
      semigroup: Semigroup.define(<>: fn {:Endo, f}, {:Endo, g} -> {:Endo, fn x -> f.(g.(x)) end} end),
      mempty: {:Endo, fn x -> x end}
    )
  end

  ### Alternative ###

  def alternative_list do
    Alternative.define(
      applicative: applicative_list(),
      empty: [],
      <|>: &++/2
    )
  end

  def alternative_maybe do
    Alternative.define(
      applicative: applicative_maybe(),
      empty: :Nothing,
      <|>: fn
        :Nothing, r -> r
        l       , _ -> l
      end
    )
  end

  ### Foldable ###

  def foldable_list do
    Foldable.define(
      foldMap: fn t, f, monoid_dict -> monoid_dict.mconcat.(:lists.map(f, t)) end
    )
  end

  def tree_empty,   do: :Empty
  def tree_leaf(x), do: {:Leaf, x}
  def tree_node(l, x, r), do: {:Node, l, x, r}

  def example_tree do
    tree_node(
      tree_node(
        tree_node(
          tree_empty(),
          1,
          tree_empty()),
        2,
        tree_leaf(3)),
      4,
      tree_node(
        tree_empty(),
        5,
        tree_node(
          tree_leaf(6),
          7,
          tree_empty())))
  end

  def foldable_tree do
    recf = fn recf -> fn
      :Empty          , _, monoid_dict -> monoid_dict.mempty
      {:Leaf, x}      , f, _           -> f.(x)
      {:Node, l, x, r}, f, monoid_dict -> recf.(recf).(l, f, monoid_dict) |> monoid_dict.mappend.(f.(x)) |> monoid_dict.mappend.(recf.(recf).(r, f, monoid_dict))
    end end
    Foldable.define(foldMap: recf.(recf))
  end
end
