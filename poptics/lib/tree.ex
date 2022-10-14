defmodule Tree do
  import Type
  data tree(a) = empty | node(tree(a), a, tree(a))

  require Applicative

  import Curry

  def inorder(mod, _m, empty()), do: Applicative.pure(empty(), mod)
  def inorder(mod, m, node(t, x, u)) do
    import Applicative
    pure(curry(node/3), mod)
    |> ap(inorder(mod, m, t), mod)
    |> ap(m.(x), mod)
    |> ap(inorder(mod, m, u), mod)
  end
end
