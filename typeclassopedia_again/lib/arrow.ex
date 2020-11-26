defmodule Arrow do
  defmacro definstance(name, category, do: body) do
    quote do
      defmodule unquote(name) do
        use Bask.Curry

        import Bask

        unquote(body)

        defmacro category, do: unquote(category)

        defoverridable_curried parallel(ar1, ar2) do
          open unquote(category), do: first(ar1) >>> arr(swap()) >>> first(ar2) >>> arr(swap())
        end

        defoverridable_curried first(ar), do: parallel(ar, category().id)
        defoverridable_curried second(ar), do: parallel(category().id, ar)

        defoverridable_curried fanout(ar1, ar2) do
          open unquote(category), do: arr(fn x -> {x, x} end) >>> parallel(ar1, ar2)
        end

        defcurried swap({x, y}), do: {y, x}
      end
    end
  end
end
