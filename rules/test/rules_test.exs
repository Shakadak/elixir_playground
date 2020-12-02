defmodule RulesTest do
  use ExUnit.Case
  doctest Rules

  test "greets the world" do
    assert Rules.hello() == :world
  end
end
