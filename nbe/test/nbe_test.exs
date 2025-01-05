defmodule NbeTest do
  use ExUnit.Case
  doctest Nbe

  import ExUnit.CaptureIO

  import Nbe

  test "assv" do
    {:x, "apples"} =
      assv(:x, [{:y, "peaches"}, {:x, "apples"}])

    false =
      assv(:x,[{:y, "peaches"}, {:z, "apples"}])
  end

  test "val" do
    import Clos

    assert clos([], :x, [:λ, [:y], :y]) =
      val([], [:λ, [:x], [:λ, [:y], :y]])

    assert clos([], :x, :x) =
      val([], [[:λ, [:x], :x], [:λ, [:x], :x]])

    assert_raise RuntimeError, "Unknown variable :x", fn -> val([], :x) end
  end

  test "run-program" do
    expected = inspect(
      [:λ, [:y], [:λ, [:z], [:z, :y]]],
      pretty: true
    ) <> "\n"

    assert ^expected = capture_io fn ->
      run_program([], [[:define, :id, [:λ, [:x], :x]],
        [:id, [:λ, [:y], [:λ, [:z], [:z, :y]]]]])
    end

    expected = inspect(
      [:λ, [:f], [:λ, [:x], [:f, [:f, :x]]]],
      pretty: true
    ) <> "\n"

    assert ^expected = capture_io fn ->
      run_program([], [
        [:define, :z,
          [:λ, [:f],
            [:λ, [:x], :x]]],
        [:define, :s,
          [:λ, [:n],
            [:λ, [:f],
              [:λ, [:x],
                [:f, [[:n, :f], :x]]]]]],
        [:s, [:s, :z]],
      ])
    end
  end

  test "freshen" do
    assert :x = freshen([], :x)
    assert :"x**" = freshen([:x, :"x*"], :x)
    assert :"y*" = freshen([:x, :y, :z], :y)

  end

  test "read-back" do
    assert [:λ, [:y], :y] =
      read_back([], val([], [[:λ, [:x], [:λ, [:y], [:x, :y]]], [:λ, [:x], :x]]))
  end

  test "with-numeral" do
    expected = inspect([:λ, [:f], [:λ, [:x], :x]]) <> "\n"
    assert ^expected = capture_io fn ->
      run_program([], with_numerals(to_church(0)))
    end

    expected = inspect([:λ, [:f], [:λ, [:x], [:f, :x]]]) <> "\n"
    assert ^expected = capture_io fn ->
      run_program([], with_numerals(to_church(1)))
    end

    expected = inspect([:λ, [:f], [:λ, [:x], [:f, [:f, [:f, [:f, :x]]]]]]) <> "\n"
    assert ^expected = capture_io fn ->
      run_program([], with_numerals(to_church(4)))
    end
  end

  test "church-add" do
    expected = inspect([:λ, [:f], [:λ, [:x], [:f, [:f, [:f, [:f, :x]]]]]]) <> "\n"

    assert ^expected = capture_io fn ->
      run_program([], with_numerals([[church_add(), to_church(2)], to_church(2)]))
    end
  end

  test "go-on" do
    import Go
    import Stop
    bigger_than_two = fn n ->
      if n > 2 do go(n) else stop(n, "Not greater than two") end
    end

    assert go(9) = go_on([
      [x, bigger_than_two.(4)],
      [y, bigger_than_two.(5)],
    ],
      (go(x + y)))

    assert stop(1, "Not greater than two") = go_on([
      [x, bigger_than_two.(1)],
      [y, bigger_than_two.(5)],
    ],
      (go(x + y)))

    assert stop(-3, "Not greater than two") = go_on([
      [x, bigger_than_two.(4)],
      [y, bigger_than_two.(-3)],
    ],
      (go(x + y)))
  end

  # 5.1 Types

  test "type=? and type?" do
    assert true = type?(:nat)
    assert false == type?([:nat])
    assert true = type?([:->, :nat, :nat])
    assert true = type_eq?(:nat, :nat)
    assert true = type_eq?(
      [:->, :nat, [:->, :nat, :nat]],
      [:->, :nat, [:->, :nat, :nat]])
    assert false == type_eq?(
      [:->, [:->, :nat, :nat], :nat],
      [:->, :nat, [:->, :nat, :nat]]
    )
  end

  # 5.2 Cheking Types
end
