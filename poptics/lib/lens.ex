defmodule Lens do
  import Type
  import Bag

  record lens(a, b, s, t) = lens %{view: (s -> a), update: ({b, s} -> t)}

  def pi1 do
    view = fn {x, _} -> x end
    update = fn {x_, {_, y}} -> {x_, y} end

    lens(view, update)
  end

  def sign do
    view = fn x -> x >= 0 end
    update = fn {b, x} -> if b do abs(x) else -abs(x) end end

    lens(view, update)
  end

  def pi11 do
    lens(v, u) = pi1()
    view = fn x -> v.(v.(x)) end
    update = fn {x_, xyz} ->
      xy = v.(xyz)
      xy_ = u.({x_, xy})
      u.({xy_, xyz})
    end

    lens(view, update)
  end

  def pi11_ do
    lens(v, _u) = pi1()
    view = fn x -> v.(v.(x)) end
    update = fn {x_, {{_x, y}, z}} -> {{x_, y}, z} end

    lens(view, update)
  end

  require Profunctor
  require Cartesian

  def lensC2P(lens(v, u), type) do
    id = &Function.identity/1
    f = &fork(v, id, &1)
    &Profunctor.dimap(f, u, Cartesian.first(&1, type), type)
  end

  def lensP2C(l), do: l.(Lens).(lens(&Bag.id/1, &Bag.fst/1))

  def piP1(cartesian), do: lensC2P(pi1(), cartesian)

  def piP1_(type) do
    fst = &Bag.fst/1
    snd = &Bag.snd/1
    id = &Bag.id/1

    f = &fork(fst, id, &1)
    g = &cross(id, snd, &1)

    &Profunctor.dimap(f, g, Cartesian.first(&1, type), type)
  end

  def piP11(cartesian), do: &piP1(cartesian).(piP1(cartesian).(&1))
  def piP11_(cartesian), do: &piP1_(cartesian).(piP1_(cartesian).(&1))

  def view(l, s) do
    import Forget
    forget(f) = l.(Forget).(forget(&Bag.id/1))
    f.(s)
  end

  def set(l, b, s) do
    l.(Function).(&Bag.const(b, &1)).(s)
  end
end

defmodule Profunctor.Lens do
  import Lens
  import Bag

  def dimap(f, g, lens(v, u)) do
    id = &id/1
    lens(&v.(f.(&1)), &g.(u.(cross(id, f, &1))))
  end
end

defmodule Cartesian.Lens do
  import Lens
  import Bag

  def first(lens(v, u)) do
    view = &v.(fst(&1))

    id = &id/1
    fst = &fst/1
    update = fn x ->
      fork(&u.(cross(id, fst, &1)), &snd(snd(&1)), x)
    end

    lens(view, update)
  end

  def second(lens(v, u)) do
    view = &v.(snd(&1))

    id = &Function.identity/1
    snd = &snd/1
    update = fn x ->
      fork(&fst(snd(&1)), &u.(cross(id, snd, &1)), x)
    end

    lens(view, update)
  end
end
