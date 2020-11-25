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
  defcurried map(_, :Nothing)  , do: :Nothing
  defcurried map(f, {:Just, x}), do: {:Just, f.(x)}
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
