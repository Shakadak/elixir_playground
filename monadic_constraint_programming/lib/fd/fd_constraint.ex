defmodule FDConstraint do
  @type fd_constraint ::
    {:fd_in, any, {integer, integer}}
  | {:fd_eq, term, integer}
  | {:fd_ne, term, term, integer}

  defmacro fd_in(term, range) do
    quote do {:fd_in, unquote(term), unquote(range)} end
  end
end
