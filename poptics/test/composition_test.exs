defmodule CompositionTest do
  use ExUnit.Case

  test "square left hand of optional pair" do
    composition = fn type -> &Prism.theP_(type).(Lens.piP1_(type).(&1)) end
    over = fn o, f, s -> o.(Function).(f).(s) end
    square = &(&1 * &1)

    optional_pair = {:Just, {3, true}}
    ret = over.(composition, square, optional_pair)
    assert ret == {:Just, {9, true}}

    optional_pair = :Nothing
    ret = over.(composition, square, optional_pair)
    assert ret == :Nothing

  end
end
