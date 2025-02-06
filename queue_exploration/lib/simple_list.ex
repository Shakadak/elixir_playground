defmodule SimpleList do
  @enforce_keys [
    :q,
  ]
  defstruct @enforce_keys

  def empty, do: %__MODULE__{q: []}

  def from_enum(l), do: %__MODULE__{q: Enum.to_list(l)}
end

defimpl CatQueue, for: SimpleList do
  def size(%@for{q: q}), do: length(q)

  def push(%@for{q: q}, x), do: %@for{q: q ++ [x]}

  def pop(%@for{q: [x | q]}), do: {x, %@for{q: q}}

  def concat(%@for{q: l}, %@for{q: r}), do: %@for{q: l ++ r}

  def to_list(%@for{} = q), do: q.q

  def empty?(%@for{q: []}), do: true
  def empty?(%@for{}), do: false
end
