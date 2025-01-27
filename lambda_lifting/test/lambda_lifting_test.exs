defmodule LambdaLiftingTest do
  use ExUnit.Case
  doctest LambdaLifting

  test "lambda lifting" do

    defmodule LL1 do
      use LambdaLifting

      def mk do
        x = 0
        y = 1
        lfn do x -> x + y end
      end

      def mk2(a) do
        lfn name: :lifted do b -> a * b end
      end
    end

    {fun, env} = LL1.mk()
    assert apply(fun, [1 | env]) == 2

    {fun, env} = LL1.mk2(2)
    assert apply(fun, [3 | env]) == 6
  end
end
