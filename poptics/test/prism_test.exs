defmodule PrismTest do
  use ExUnit.Case

  # concrete

  test "the view" do
    require Either

    s1 = {:Just, 1}
    e_a = Prism.the().match.(s1)
    assert e_a == Either.right(1)

    s2 = :Nothing
    e_t = Prism.the().match.(s2)
    assert e_t == Either.left(:Nothing)
  end

  test "the update" do
    b = 12
    t = Prism.the().build.(b)
    assert t == {:Just, 12}
  end

  test "whole view" do
    require Either

    s = 1.2
    e_t = Prism.whole().match.(s)
    assert e_t == Either.left(1.2)

    s = 4.0
    e_a = Prism.whole().match.(s)
    assert e_a == Either.right(4)
  end

  test "whole update" do
    b = 12
    t = Prism.whole().build.(b)
    assert t === 12.0
  end

  # profunctor

  test "theP view" do
    require Either

    s1 = {:Just, 1}
    e_a = Prism.matching(&Prism.theP/1, s1)
    assert e_a == Either.right(1)

    s2 = :Nothing
    e_t = Prism.matching(&Prism.theP/1, s2)
    assert e_t == Either.left(:Nothing)
  end

  test "theP update" do
    b = 12
    t = Prism.review(&Prism.theP/1, b)
    assert t == {:Just, 12}
  end

  test "theP' view" do
    require Either

    s1 = {:Just, 1}
    e_a = Prism.matching(&Prism.theP_/1, s1)
    assert e_a == Either.right(1)

    s2 = :Nothing
    e_t = Prism.matching(&Prism.theP_/1, s2)
    assert e_t == Either.left(:Nothing)
  end

  test "theP' update" do
    b = 12
    t = Prism.review(&Prism.theP_/1, b)
    assert t == {:Just, 12}
  end
end
