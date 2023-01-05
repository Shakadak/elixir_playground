defmodule Papl.DisjointSet do
  defmacro some(x), do: {:some, x}
  defmacro none, do: :none

  defmacro elt(val, parent), do: {:%{}, [], [val: val, parent: parent]}

  def is_same_element(elt(e1, _), elt(e2, _)), do: e1 == e2

  def is_in_same_same_set(x, y, sets) do
    s1 = fynd(x, sets)
    s2 = fynd(y, sets)
    s1 == s2
  end

  def fynd(e, sets) do
    case sets do
      [] -> raise("fynd: shouldn't have gotten here")
      [f | r] ->
        if is_same_element(f, e) do
          case f.parent do
            none() -> f
            some(p) -> fynd(p, sets)
          end
        else
            fynd(e, r)
        end
    end
  end

  def identical(x, y), do: x === y

  def union(e1, e2, s) do
    s1 = fynd(e1, s)
    s2 = fynd(e2, s)
    if identical(s1, s2) do
      s
    else
      update_set_with(s, s1, s2)
    end
  end

  def update_set_with(s, child, parent) do
    case s do
      [] -> raise("update: shouldn't have gotten here")
      [f | r] ->
        if is_same_element(f, child) do
          [elt(f.val, some(parent)) | r]
        else
          [f | update_set_with(r, child, parent)]
        end
    end
  end

  def check do
    s0 = Enum.map([0, 1, 2, 3, 4, 5, 6, 7], &elt(&1, none()))
    s1 = union(Enum.at(s0, 0), Enum.at(s0, 2), s0)
    s2 = union(Enum.at(s1, 0), Enum.at(s1, 3), s1)
    s3 = union(Enum.at(s2, 3), Enum.at(s2, 5), s2)
    _ = IO.inspect(s3)
    true = is_same_element(fynd(Enum.at(s0, 0), s3), fynd(Enum.at(s0, 5), s3))
    true = is_same_element(fynd(Enum.at(s0, 2), s3), fynd(Enum.at(s0, 5), s3))
    true = is_same_element(fynd(Enum.at(s0, 3), s3), fynd(Enum.at(s0, 5), s3))
    true = is_same_element(fynd(Enum.at(s0, 5), s3), fynd(Enum.at(s0, 5), s3))
    true = is_same_element(fynd(Enum.at(s0, 7), s3), fynd(Enum.at(s0, 7), s3))
  end
end
