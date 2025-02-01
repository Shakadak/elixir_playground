defmodule ReflectionWithoutRemorseTest do
  use ExUnit.Case
  doctest ReflectionWithoutRemorse

  test "greets the world" do
    assert ReflectionWithoutRemorse.hello() == :world
  end
end
