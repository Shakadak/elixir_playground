defprotocol CatQueue do
  @spec push(t, any) :: t
  def push(q, e)

  @spec pop(t) :: {any, t}
  def pop(q)

  @spec concat(t, t) :: t
  def concat(l, r)

  @spec to_list(t) :: [any]
  def to_list(q)

  @spec size(t) :: non_neg_integer
  def size(q)

  @spec empty?(t) :: boolean
  def empty?(q)
end
