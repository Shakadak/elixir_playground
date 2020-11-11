
defmodule Typeclassopedia do
  @moduledoc """
  Documentation for `Typeclassopedia`.
  """

  # FUNCTORS

  def functor_list, do: Functor.define(map: &:lists.map/2)

  def functor_maybe, do: Functor.define(map: fn
    _, {:nothing} -> {:nothing}
    f, {:just, x} -> {:just, f.(x)}
  end)

  def functor_either, do: Functor.define(map: fn
    _, {:left, _} = t_a -> t_a
    f, {:right, x} -> {:right, f.(x)}
  end)

  # (a -> b) -> f a -> f b = (a -> b) -> (e -> a) -> (e -> b)
  # f a = (e -> a) # a -> b = (e -> a) -> (e -> b)
  def functor_function_out, do: Functor.define(map: fn f, fa -> fn x -> f.(fa.(x)) end end)

  def functor_tuple2, do: Functor.define(map: fn f, {e, x} -> {e, f.(x)} end)

  def functor_pair, do: Functor.define(map: fn f, {x, y} -> {f.(x), f.(y)} end)

  def itree_leaf(f), do: {:leaf, f}   # Leaf (Int -> a)
  def itree_node(xs), do: {:node, xs} # Node [Itree a]

  def functor_itree do
    
    recf = fn recf -> fn
      f, {:leaf, g} -> {:leaf, fn x -> f.(g.(x)) end}
      f, {:node, xs} -> {:node, :lists.map(fn x -> recf.(recf).(f, x) end, xs)}
    end end

    Functor.define(map: recf.(recf))
  end

  # APPLICATIVES

  def applicative_maybe, do: Applicative.define(
    functor: functor_maybe(),
    pure: fn x -> {:just, x} end,
    apA: fn
      {:just, f}, {:just, x} -> {:just, f.(x)}
      _, _ -> {:nothing}
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
    apA: fn fs, xs -> for f <- fs, x <- xs, do: f.(x) end
    #liftA2: fn f, xs, ys -> for x <- xs, y <- ys, do: f.(x, y) end
  )

  def sequenceAL(mx_s, dict), do: :lists.foldr(fn mx, m_xs -> dict.liftA2.(fn x, xs -> [x | xs] end, mx, m_xs) end, dict.pure.([]), mx_s)

  def monad_identity, do: Monad.define(
    applicative: Applicative.define(
      functor: Functor.define(
        map: fn f, {x} -> {f.(x)} end
      ),
      pure: fn x -> {x} end,
      apA: fn {f}, {x} -> {f.(x)} end
    ),
    bind: fn {x}, f -> f.(x) end
  )

  def monad_maybe, do: Monad.define(
    applicative: applicative_maybe(),
    bind: fn
      {:just, x}, f -> f.(x)
      {:nothing}, _ -> {:nothing}
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
end
