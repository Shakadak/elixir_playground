defmodule NbeTest do
  use ExUnit.Case
  doctest Nbe

  test "greets the world" do
    assert Nbe.hello() == :world
  end
end
