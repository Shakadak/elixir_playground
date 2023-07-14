defmodule Mul do
  require Class

  Class.mk :mul_super, 0
  Class.mk :mul, 2

  defmacro mk(eq, num) do
    quote do
      def mul_super, do: {unquote(eq), unquote(num)}
      def mul(x, y), do: unquote(__MODULE__).mul_default_loop(x, y, mul_super())
    end
  end

  def mul_default_loop(x, y, {eq, num} = dicts) do
    import Num
    import Eq
    cond do
      eq(x, from_int(0, num), eq) -> from_int(0, num)
      eq(x, from_int(1, num), eq) -> y
      :otherwise -> add(y, mul_default_loop(add(x, from_int(-1, num), num), y, dicts), num)
    end
  end
end

defmodule Mul.Bool do
  require Mul
  Mul.mk Eq.Bool, Num.Bool
end

defmodule Mul.Int do
  def mul_super, do: fn -> {Eq.Int, Num.Int} end
  def mul, do: fn (x, y) -> x *  y end
end
