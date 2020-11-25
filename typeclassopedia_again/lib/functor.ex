defmodule Functor do
  defmacro definstance(name, do: body) do
    quote do
      defmodule unquote(name) do
        use Base.Curry

        unquote(body)

        defoverridable_curried replace_with_left(a, tb), do: map(Base.Data.Function.const(a), tb)
      end
    end
  end
end
