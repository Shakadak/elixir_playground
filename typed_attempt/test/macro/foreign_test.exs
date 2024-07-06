defmodule Macro.ForeignTest do
  use ExUnit.Case

  test "foreign Kernel.+" do
    {:foreign, _, _ast} = quote do
      foreign import Kernel.+, -: (int(), int() -> int())
    end
  end
end
