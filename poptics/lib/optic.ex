defmodule Optic do
  import Type

  record optic(p, a, b, s, t) = optic %{run: (p(a, b) -> p(s, t))}
end
