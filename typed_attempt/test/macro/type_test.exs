defmodule Macro.TypeTest do
  use ExUnit.Case

  test "parse now spec" do
    {:type, _, ast} = quote do
      type now, -: (-> io(time()))
    end
  end
end
