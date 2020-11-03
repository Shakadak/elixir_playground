defmodule DemistfyingTypeClasses do
  @moduledoc """
  http://okmij.org/ftp/Computation/typeclass.html#dict
  """

  def show_bool, do: %{show: fn
    true -> "True"
    false -> "False"
  end}

  def show_int, do: %{show: &Integer.to_string/1}

  def print(dict, x), do: IO.puts(dict.show.(x))

  def test_print, do: print(show_bool(), true)

  def sum(dict, xs), do: List.foldr(xs, dict.from_int.(0), dict.add)

  # Sample instance
  def num_int, do: %{from_int: fn x -> x end, add: &+/2}

  def print_incr({show, num}, x), do: print(show, num.add.(x, num.from_int.(1)))

  def print_incr_int(x), do: print_incr({show_int(), num_int()}, x)

  def show_list(dict), do: %{show: fn xs -> "[" <> Enum.map_join(xs, ", ", dict.show) <> "]" end}

  def testls, do: show_list(show_int()).show.([1, 2, 3])

  def mul_default(super), do: %{
    mul_super: super,
    mul: fn x, y -> mul_default_loop(super, x, y) end
  }

  def mul_default_loop({eq, num} = dicts, x, y) do
    cond do
      eq.eq.(x, num.from_int.(0)) -> num.from_int.(0)
      eq.eq.(x, num.from_int.(1)) -> y
      :otherwise -> num.add.(y, mul_default_loop(dicts, num.add.(x, num.from_int.(-1)), y))
    end
  end

  def mul_bool, do: mul_default({%{eq: &==/2}, %{from_int: fn _ -> nil end, add: fn _, _ -> nil end}})

  def mul_int, do: %{mul_super: {%{eq: &==/2}, num_int()}, mul: &*/2}

  def dot(%{mul_super: {_, num}} = dict, xs, ys), do: sum(num, Enum.map(Enum.zip(xs, ys), fn {x, y} -> dict.mul.(x, y) end))

  def test_dot, do: dot(mul_int(), [1, 2, 3], [4, 5, 6])

  def print_nested(show, 0, x), do: print(show, x)
  def print_nested(show, n, x), do: print_nested(show_list(show), n - 1, List.duplicate(x, n))

  def test_nested do
    n = String.to_integer(String.trim(IO.gets("Enter nesting amount: ")))
    print_nested(show_int(), n, 5)
  end
end
