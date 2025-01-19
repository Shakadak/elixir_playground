defprotocol Walk.Protocol do
  def gfoldl(d, k, z)
end

defmodule Walk do
  def gmapT(f, adt) do
    k = fn c -> fn x -> c.(f.(x)) end end
    Walk.Protocol.gfoldl(adt, k, & &1)
  end

  def gmapQ(f, adt) do
    k = fn c -> fn x -> fn rs -> c.([f.(x) | rs]) end end end
    Walk.Protocol.gfoldl(adt, k, fn x, _ -> x end)
  end
end

defimpl Walk.Protocol, for: List do
  def gfoldl([], _, z), do: z.([])
  def gfoldl([x | xs], k, z), do: z.(fn y -> fn ys -> [y | ys] end end) |> k.(x) |> k.(xs)
end
