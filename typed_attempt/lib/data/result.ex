defmodule Data.Result do
  use ComputationExpression, debug: false

  defmacro ok(x), do: {:ok, x}
  defmacro error(x), do: {:error, x}

  def pure(x), do: ok(x)

  def map(ok(x), f), do: ok(f.(x))
  def map(error(y), _), do: error(y)

  def bind(ok(x), f), do: f.(x)
  def bind(error(_) = y, _), do: y

  def join(ok(x)), do: x
  def join(error(_) = y), do: y

  def from_ok!(ok(x)), do: x
  def from_error!(error(x)), do: x

  def sequence(xs), do: mapM(xs, & &1)

  def mapM(as, f) do
    k = fn a, r ->
      compute do
        let! x = f.(a)
        let! xs = r
        pure [x | xs]
      end
    end

    List.foldr(as, pure([]), k)
  end

  # foldlM :: (Monad m) => [a], b, (a, b -> m b) -> m b
  def foldlM(xs, z0, f) do
    c = fn x, k -> fn acc -> f.(x, acc) |> bind(k) end end
    List.foldr(xs, &pure/1, c).(z0)
    # foldr c return xs z0
  end
end
