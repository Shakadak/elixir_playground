
defmodule Typeclassopedia do
  @moduledoc """
  Documentation for `Typeclassopedia`.
  """

  def fmap_list([], _), do: []
  def fmap_list([x | xs], f), do: [f.(x) | fmap_list(xs, f)]
  def functor_list, do: Functor.define(fmap: fn x, f -> fmap_list(x, f) end)

  def functor_maybe, do: Functor.define(fmap: fn
    {:nothing}, _ -> {:nothing}
    {:just, x}, f -> {:just, f.(x)}
  end)

  def functor_either, do: Functor.define(fmap: fn
    {:left, _} = t_a, _ -> t_a
    {:right, x}, f -> {:right, f.(x)}
  end)
end
