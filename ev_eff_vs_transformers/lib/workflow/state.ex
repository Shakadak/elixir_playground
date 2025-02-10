defmodule Workflow.State do
  defmacro _Bind(m, f) do
    quote do
      require Wrapped.State
      Wrapped.State.bind(unquote(m), unquote(f))
    end
  end

  defmacro _Pure(x) do
    quote do
      Wrapped.State.pure(unquote(x))
    end
  end

  defmacro _PureFrom(m) do
    m
  end
end
