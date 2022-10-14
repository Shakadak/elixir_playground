defmodule Lazy do
  defmacro delay(ast) do
    quote do: {:Lazy, fn -> unquote(ast) end}
  end
  defmacro force(ast) do
    quote do
      {:Lazy, thunk} = unquote(ast) ; thunk.()
    end
  end
end

defmodule Profunctor.Lazy do
  def mk(profunctor) do
    %{Profunctor => %{dimap: &dimap(&1, &2, &3, profunctor)}}
  end

  def dimap(f, g, h, profunctor) do
    import Lazy
    require Profunctor
    Profunctor.dimap(f, g, force(h), profunctor)
  end
end
