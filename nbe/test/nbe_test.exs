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
end
