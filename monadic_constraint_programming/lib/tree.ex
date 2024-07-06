defmodule Tree do
  @type tree(solver, a) ::
    {:return, a}
  | {:new_var, (Solver.term(solver) -> tree(solver, a))}
  | {:add, Solver.constraint(solver), tree(solver, a)}

  defmacro return(a), do: {:return, a}

  defmacro new_var(f), do: {:new_var, f}

  defmacro add(constraint, tree) do
    quote do {:add, unquote(constraint), unquote(tree)} end
  end

  def pure(a), do: return(a)

  def bind(return(x), k), do: k.(x)
  def bind(new_var(f), k), do: new_var(fn v -> f.(v) |> bind(k) end)

end
