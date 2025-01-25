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
    end
    {fun, env} = LL1.mk()
    assert apply(fun, [1] ++ env) |> IO.inspect() == 2
  end
end
