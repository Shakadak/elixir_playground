defmodule AccessMacroTest do
  use ExUnit.Case
  doctest AccessMacro

  test "greets the world" do
    assert AccessMacro.hello() == :world
  end
end
