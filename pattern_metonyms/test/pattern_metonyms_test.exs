defmodule PatternMetonymsTest do
  use ExUnit.Case
  doctest PatternMetonyms

  test "maybe pair" do
    defmodule TestM2 do
      import PatternMetonyms

      pattern just2(a, b) = {:Just, {a, b}}

      def f(just2(x, y)), do: x + y
      def foo, do: f(just2(3, 2))
    end

    assert TestM2.foo == 5
  end

  test "maybe triplet" do
    defmodule TestM3 do
      import PatternMetonyms

      pattern just3(a, b, c) =
        {:Just, {a, b, c}}

      def g(just3(x, y, _)), do: x + y
      def bar, do: g(just3(3, 2, 1))
    end

    assert TestM3.bar == 5
  end

  test "maybe singleton" do
    defmodule TestM1 do
      import PatternMetonyms

      pattern just1(a) = {:Just, a}

      def h(just1(x)), do: -x
      def baz, do: h(just1(3))
    end

    assert TestM1.baz == -3
  end

  test "list head" do
    defmodule TestL1 do
      import PatternMetonyms

      pattern head(x) <- [x | _]

      def f(head(x)), do: x
    end

    assert TestL1.f([1, 2, 3]) == 1
  end

  test "raise list head" do
    assert_raise CompileError, fn ->
      defmodule TestL2 do
        import PatternMetonyms

        pattern head(x) <- [x | _]

        def g, do: head(4)
      end
    end
  end

  test "view maybe pair" do
    defmodule TestVM2 do
      import PatternMetonyms

      pattern just2(a, b) = {:Just, {a, b}}

      def f(x) do
        view x do
          just2(x, y) -> x + y
          :Nothing -> 0
        end
      end

      def foo, do: f(just2(3, 2))
    end

    assert TestVM2.foo == 5
  end

  test "view safe head" do
    defmodule TestVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def safeHead(xs) do
        view xs do
          (uncons -> {:Just, {x, _}}) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestVL1.safeHead([]) == :Nothing
    assert TestVL1.safeHead([1]) == {:Just, 1}
  end
end
