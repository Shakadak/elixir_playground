defmodule TraversalTest do
  use ExUnit.Case

  test "tree state" do
    import Tree

    tree = node(node(empty(), 2, empty()), 3, node(empty(), 4, empty()))
    ret = Tree.inorder(State, &State.countOdd/1, tree).run.(0)
    ret_tree = node(node(empty(), false, empty()), true, node(empty(), false, empty()))
    assert ret == {ret_tree, 1}
  end

  test "fuse . inorderC = id" do
    import Tree ; tree = node(node(empty(), 2, empty()), 3, node(empty(), 4, empty()))

    extracted_tree =
      Traversal.inorderC.extract.(tree)
      |> FunList.fuse()

    assert extracted_tree == tree
  end

  test "profunctor duplicate :a tree" do
    import Tree ; tree = node(node(empty(), 2, empty()), 3, node(empty(), 4, empty()))

    _t = Traversal.traverseOf(&Traversal.inorderP/1, &List.duplicate(:a, &1), tree, List)
         |> IO.inspect()

    assert false
  end
end
