defmodule EvEffTest do
  use ExUnit.Case
  doctest EvEff

  import EvEff
  import Eff

  test "greets the world" do
    assert EvEff.hello() == :world
  end

  test "Reader world" do
    assert runEff(helloWorld()) == "hello world"
  end

  test "Exception Maybe" do
    import Exn
    assert runEff(toMaybe(safeDiv(42, 2))) == {Just, 21}
    assert runEff(toMaybe(safeDiv(42, 0))) == Nothing
  end

  test "Exception default" do
    import Exn
    assert runEff(exceptDefault(0, safeDiv(42, 2))) == 21
    assert runEff(exceptDefault(0, safeDiv(42, 0))) == 0
  end

  test "State" do
    import State
    assert runEff(state(true, invert())) == false
  end

  test "State as a Function" do
    import State
    assert runEff(state2(true, invert())) == false
  end
end
