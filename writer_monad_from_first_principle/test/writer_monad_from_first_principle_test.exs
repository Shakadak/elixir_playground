defmodule WriterMonadFromFirstPrincipleTest do
  use ExUnit.Case
  doctest WriterMonadFromFirstPrinciple

  test "greets the world" do
    assert WriterMonadFromFirstPrinciple.hello() == :world
  end
end
