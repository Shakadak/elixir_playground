defmodule SimpleListTest do
  use ExUnit.Case
  doctest QueueExploration

  use ExUnitProperties

  property "from_list |> to_list = id" do
    check all list <- list_of(term()) do
      assert CatQueue.to_list(SimpleList.from_enum(list)) == list
    end
  end

  property "reduce zero push to_list = id" do
    check all list <- list_of(term()) do
      q = Enum.reduce(list, SimpleList.empty(), &CatQueue.push(&2, &1))
      assert CatQueue.to_list(q) == list
    end
  end

  property "count is coherent" do
    check all list <- list_of(term()) do
      q = SimpleList.from_enum(list)
      assert CatQueue.size(q) == length(list)
    end
  end

  property "to list size is coherent" do
    check all list <- list_of(term()) do
      q = SimpleList.from_enum(list)
      assert length(CatQueue.to_list(q)) == length(list)
    end
  end

  property "all in == all out" do
    check all list <- list_of(term()) do
      q = SimpleList.from_enum(list)
      all = MapSet.new(Stream.unfold(q, fn q ->
        if not CatQueue.empty?(q) do
          CatQueue.pop(q)
        end
      end))

      assert Enum.all?(list, & &1 in all)
    end
  end

  property "popping in proper order" do
    check all list <- nonempty(list_of(term())) do
      q = SimpleList.from_enum(list)
      actual = Enum.to_list(Stream.unfold(q, fn q ->
        if not CatQueue.empty?(q) do
          CatQueue.pop(q)
        end
      end))

      assert actual == list
    end
  end

  property "push is at the end" do
    check all list <- list_of(term()),
      x <- term() do
      q = SimpleList.from_enum(list)
      q = CatQueue.push(q, x)

      assert CatQueue.to_list(q) == list ++ [x]
    end
  end

  property "pop is at the front" do
    check all list <- nonempty(list_of(term())) do
      q = SimpleList.from_enum(list)
      {e, q} = CatQueue.pop(q)
      [head | tail] = list

      assert CatQueue.to_list(q) == tail
      assert e == head
    end
  end
end
