defmodule Workflow.ResultState do
  ### COMPUTATION EXPRESSION -------------------------------------------------------------

  defmacro _Pure(x), do: (quote do Wrapped.ResultState.pure(unquote(x)) end)

  defmacro _Bind(m, f), do: (quote do Wrapped.ResultState.bind(unquote(m), unquote(f)) end)

  defmacro _PureFrom(m), do: m

  #defmacro _Zero, do: (quote do Wrapped.ResultState.pure({}) end)

  #defmacro _Combine(l, rk), do: (quote do Wrapped.ResultState.bind(unquote(l), fn {} -> unquote(rk).() end) end)

  #defmacro _Delay(k), do: k

  #defmacro _Run(k), do: (quote do unquote(k).() end)
end
