defmodule LensTest do
  use ExUnit.Case

  # concrete

  test "π1 view" do
    s = {1, 2}
    a = Lens.pi1().view.(s)

    assert a == 1
  end

  test "π1 update" do
    s = {1, 2}
    b = 0
    t = Lens.pi1().update.({b, s})

    assert t == {0, 2}
  end

  test "sign view" do
    s = 1
    a = Lens.sign().view.(s)

    assert a == true

    s = 0
    a = Lens.sign().view.(s)

    assert a == true

    s = -1
    a = Lens.sign().view.(s)

    assert a == false
  end

  test "sign update" do
    s = 1
    b = true
    t = Lens.sign().update.({b, s})

    assert t == 1

    s = 1
    b = false
    t = Lens.sign().update.({b, s})

    assert t == -1

    s = -1
    b = true
    t = Lens.sign().update.({b, s})

    assert t == 1

    s = -1
    b = false
    t = Lens.sign().update.({b, s})

    assert t == -1

    s = 0
    b = true
    t = Lens.sign().update.({b, s})

    assert t == 0

    s = 0
    b = false
    t = Lens.sign().update.({b, s})

    assert t == 0
  end

  test "π11 view" do
    s = {{1, 3}, 2}
    a = Lens.pi11().view.(s)

    assert a == 1
  end

  test "π11 update" do
    s = {{1, 3}, 2}
    b = 0
    t = Lens.pi11().update.({b, s})

    assert t == {{0, 3}, 2}
  end

  test "π11' view" do
    s = {{1, 3}, 2}
    a = Lens.pi11_().view.(s)

    assert a == 1
  end

  test "π11' update" do
    s = {{1, 3}, 2}
    b = 0
    t = Lens.pi11_().update.({b, s})

    assert t == {{0, 3}, 2}
  end

  # profunctor to concrete

  test "π1 p2c view" do
    s = {1, 2}
    a = Lens.lensP2C(&Lens.piP1_/1).view.(s)

    assert a == 1
  end

  test "π1 p2c update" do
    s = {1, 2}
    b = 0
    t = Lens.lensP2C(&Lens.piP1_/1).update.({b, s})

    assert t == {0, 2}
  end

  test "π11' p2c view" do
    s = {{1, 3}, 2}
    a = Lens.lensP2C(&Lens.piP11_/1).view.(s)

    assert a == 1
  end

  test "π11' p2c update" do
    s = {{1, 3}, 2}
    b = 0
    t = Lens.lensP2C(&Lens.piP11_/1).update.({b, s})

    assert t == {{0, 3}, 2}
  end

  # profunctor

  test "πP1 view" do
    view = fn l, s ->
      import UpStar
      dict = Cartesian.UpStar.mk(Const)
      l.(dict).(up_star(&Bag.id/1)).unUpStar.(s)
    end

    s = {1, 2}
    a = view.(&Lens.piP1/1, s)

    assert a == 1
  end

  test "πP1 update" do
    set = fn l, b, s ->
      dict = Function
      l.(dict).(&Bag.const(b, &1)).(s)
    end

    s = {1, 2}
    b = 0
    t = set.(&Lens.piP1/1, b, s)

    assert t == {0, 2}
  end

  test "πP11 view" do
    view = fn l, s ->
      import UpStar
      dict = Cartesian.UpStar.mk(Const)
      l.(dict).(up_star(&Bag.id/1)).unUpStar.(s)
    end

    s = {{1, 3}, 2}
    a = view.(&Lens.piP11/1, s)

    assert a == 1
  end

  test "πP11 update" do
    set = fn l, b, s ->
      dict = Function
      l.(dict).(&Bag.const(b, &1)).(s)
    end

    s = {{1, 3}, 2}
    b = 0
    t = set.(&Lens.piP11/1, b, s)

    assert t == {{0, 3}, 2}
  end

  test "πP11' view" do
    s = {{1, 3}, 2}
    a = Lens.view(&Lens.piP11_/1, s)

    assert a == 1
  end

  test "πP11' update" do
    s = {{1, 3}, 2}
    b = 0
    t = Lens.set(&Lens.piP11_/1, b, s)

    assert t == {{0, 3}, 2}
  end

end
