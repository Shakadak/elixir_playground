defmodule ExpertSystemTest do
  use ExUnit.Case
  doctest ExpertSystem

  test "greets the world" do
    assert ExpertSystem.hello() == :world
  end
end
