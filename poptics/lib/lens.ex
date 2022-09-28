defmodule Lens do
  @enforce_keys [:view, :update]
  defstruct [:view, :update]

  defmacro lens(view, update) do
    quote do
      %unquote(__MODULE__){view: unquote(view), update: unquote(update)}
    end
  end

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
end
