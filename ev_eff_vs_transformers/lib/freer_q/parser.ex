defmodule FreerQ.Parser do
  defmacro satisfy(p), do: {Satisfy, p}

  def parse(_input, _action) do
  end
end
