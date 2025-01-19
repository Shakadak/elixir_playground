defmodule SyntaxTest do
  use ExUnit.Case
  doctest Syntax

  import Syntax

  test "aeq on id" do
    xName = "x"
    yName = "y"

    idx = lam(bind(xName, var(xName)))
    idy = lam(bind(yName, var(yName)))

    assert aeq(idx, idy)
  end
end
