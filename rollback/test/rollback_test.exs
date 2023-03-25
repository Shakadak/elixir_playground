defmodule RollbackTest do
  use ExUnit.Case
  doctest Rollback

  test "greets the world" do
    assert Rollback.hello() == :world
  end
end
