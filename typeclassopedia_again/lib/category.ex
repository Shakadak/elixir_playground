defmodule Category do
  defmacro definstance(name, do: body) do
    quote do
      defmodule unquote(name) do
        use Base.Curry

        import Base

        unquote(body)

        defoverridable_curried f >>> g, do: open __MODULE__, f .. g
        defoverridable_curried f <<< g, do: open __MODULE__, g .. f

      end
    end
  end
end
