defmodule PiForallTest do
  use ExUnit.Case
  doctest PiForall

  test "greets the world" do
    assert PiForall.hello() == :world
  end
end
