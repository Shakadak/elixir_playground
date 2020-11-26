defmodule Monad do
  defmacro definstance(name, applicative, do: body) do
    quote do
      defmodule unquote(name) do
        use Bask.Curry

        defoverridable_curried return(x), do: unquote(applicative).pure(x)
        defoverridable_curried mx ~>> f, do: bind(mx, f)
        defoverridable_curried rightM(ml, mr), do: bind(ml, fn _ -> mr end)
        defoverridable_curried join(mma), do: bind(mma, fn x -> x end)

        unquote(body)

      end
    end
  end
end
