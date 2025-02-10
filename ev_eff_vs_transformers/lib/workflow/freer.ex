defmodule Workflow.Freer do
  defmacro _Bind(m, f) do
    quote do
    require Freer
    Freer.bind(unquote(m), unquote(f))
    end
  end

  defmacro _Pure(x) do
    quote do
    require Freer
    Freer.pure(unquote(x))
    end
  end

  defmacro _PureFrom(m), do: m
end
