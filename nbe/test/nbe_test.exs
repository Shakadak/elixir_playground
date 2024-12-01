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

    assert clos([], :x, [:lam, [:y], :y]) =
      val([], [:lam, [:x], [:lam, [:y], :y]])

    assert clos([], :x, :x) =
      val([], [[:lam, [:x], :x], [:lam, [:x], :x]])

    assert_raise RuntimeError, "Unknown variable :x", fn -> val([], :x) end
  end

  test "run-program" do
    import Clos

    cmp = inspect(
      clos([{:id, clos([], :x, :x)}], :y, [:lam, [:z], [:z, :y]]),
      pretty: true
    ) <> "\n"
    assert ^cmp = capture_io fn ->
      run_program([], [[:define, :id, [:lam, [:x], :x]],
        [:id, [:lam, [:y], [:lam, [:z], [:z, :y]]]]])
    end

    cmp = inspect(
      clos(
        [
          {:n, clos([{:n, clos([], :f, [:lam, [:x], :x])},{:z, clos([], :f, [:lam, [:x], :x])}], :f, [:lam, [:x], [:f, [[:n, :f], :x]]]) },
          {:z, clos([], :f, [:lam, [:x], :x])},
        ],
        :f,
        [:lam, [:x], [:f, [[:n, :f], :x]]]
      ),
      pretty: true
    ) <> "\n"

    assert ^cmp = capture_io fn ->
      run_program([], [
        [:define, :z,
          [:lam, [:f],
            [:lam, [:x], :x]]],
        [:define, :s,
          [:lam, [:n],
            [:lam, [:f],
              [:lam, [:x],
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
end
