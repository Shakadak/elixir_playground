defmodule MonadChallengesTest do
  use ExUnit.Case
  doctest MonadChallenges

  test "greets the world" do
    assert MonadChallenges.hello() == :world
  end
end
