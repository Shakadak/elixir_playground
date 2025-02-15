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

defmodule Workflow.Freer.Q do
  defmacro _Bind(m, f) do
    quote do
    require Freer.Q
    Freer.Q.bind(unquote(m), unquote(f))
    end
  end

  defmacro _Pure(x) do
    quote do
    require Freer.Q
    Freer.Q.pure(unquote(x))
    end
  end

  defmacro _PureFrom(m), do: m
end
