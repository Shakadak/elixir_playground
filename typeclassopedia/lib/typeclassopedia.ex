
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
  )

  def sequenceAL(mx_s, dict), do: :lists.foldr(fn mx, m_xs -> dict.liftA2.(fn x, xs -> [x | xs] end, mx, m_xs) end, dict.pure.([]), mx_s)
end
