defmodule TraversalTest do
  use ExUnit.Case

  test "tree state" do
    import Tree

    tree = node(node(empty(), 2, empty()), 3, node(empty(), 4, empty()))
    ret = Tree.inorder(State, &State.countOdd/1, tree).run.(0)
    ret_tree = node(node(empty(), false, empty()), true, node(empty(), false, empty()))
    assert ret == {ret_tree, 1}

    #Traversal.inorderC.extract.(tree)
    #|> IO.inspect()
  end
end
