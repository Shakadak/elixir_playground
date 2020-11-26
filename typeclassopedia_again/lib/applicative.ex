defmodule Applicative do
  defmacro definstance(name, functor, do: body) do
    quote do
      defmodule unquote(name) do
        use Bask.Curry

        defoverridable_curried tf <~> tx, do: liftA2(fn x -> x end, tf, tx)
        defoverridable_curried liftA2(f, tx, ty), do: unquote(functor).map(f, tx) <~> ty
        defoverridable_curried leftA(tx, ty), do: liftA2(Bask.Data.Function.const, tx, ty)
        defoverridable_curried rightA(tx, ty), do: liftA2(Bask.Data.Function.const, ty, tx)
        defoverridable_curried liftA(f, tx), do: pure(f) <~> tx
        defoverridable_curried liftA3(f, tx, ty, tz), do: liftA2(f, tx, ty) <~> tz

        unquote(body)

      end
    end
  end
end
