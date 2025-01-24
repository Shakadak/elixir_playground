defmodule LambdaLiftingTest do
  use ExUnit.Case
  doctest LambdaLifting

  test "greets the world" do
    assert LambdaLifting.hello() == :world
  end
end
