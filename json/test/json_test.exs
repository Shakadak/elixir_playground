defmodule JsonTest do
  use ExUnit.Case
  doctest Json

  test "greets the world" do
    assert Json.hello() == :world
  end
end
