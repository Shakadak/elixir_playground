defmodule Stream.Step do
  defmacrop step, do: :"$step@#{__MODULE__}"
  def step(stream) do
    Enumerable.reduce(stream, {:cont, {}}, fn x, _acc -> {:suspend, x} end)
    |> case do
      {:suspended, value, cont} ->
        {:stepped, value, fn acc, _fun -> cont.(acc) end}

      {:halted, last} ->
        {:stepped, last, fn _acc, _fun -> {:done, {}} end}

      {:done, {}} -> :done
    end
  end
  def restep(stream) do
    Enumerable.reduce(stream, {:cont, step()}, fn
      x, step() -> {:suspend, x}
      x, acc ->
        IO.inspect(x, label: "elem")
        IO.inspect(acc, label: "acc1")
    end)
    |> case do
      {:suspended, value, cont} ->
        {:stepped, value, fn
          {:cont, step()}, fun ->
            cont.(acc)
          acc, fun ->
            IO.inspect(fun, label: "fun")
            IO.inspect(acc, label: "acc")
            cont.(acc)
        end}

      {:halted, last} ->
        {:stepped, last, fn _acc, _fun -> {:done, {}} end}

      {:done, {}} -> :done
    end
  end
end
