defmodule QueueExplorationTest do
  use ExUnit.Case
  doctest QueueExploration

  test "greets the world" do
    assert QueueExploration.hello() == :world
  end

  use ExUnitProperties

  property "length/1 is always >= 0" do
    check all list <- list_of(term()) do
      assert length(list) >= 0
    end
  end

  property "the in/2 operator works with lists" do
    check all list <- list_of(term()),
      list != [],
      elem <- member_of(list) do
        assert elem in list
      end
  end

  property "bin1 <> bin2 always starts with bin1" do
    check all bin1 <- binary(),
      bin2 <- binary() do
      assert String.starts_with?(bin1 <> bin2, bin1)
    end
  end
end
