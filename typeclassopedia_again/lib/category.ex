defmodule Category do
  defmacro definstance(name, do: body) do
    quote do
      defmodule unquote(name) do
        use Bask.Curry

        import Bask

        defoverridable_curried f >>> g, do: open __MODULE__, f .. g
        defoverridable_curried f <<< g, do: open __MODULE__, g .. f

        unquote(body)

      end
    end
  end
end
