defmodule Data.Result do
  @moduledoc """
  The Result type represents values with two possibilities: an error value, or a correct value.
  This is typically used to represent a happy path, where `ok/1` represents continuation, and `error/1` represents early return.
  We will call this a workflow.

  You can use `for` comprehensions with this type:

      iex> for x <- Data.Result.pure(10),
      ...>     y <- Data.Result.pure(2),
      ...> into: Data.Result.pure({}) do
      ...>  x * y
      ...> end
      Data.Result.ok(20)

      iex> for x <- Data.Result.pure(10),
      ...>     y <- Data.Result.error(2),
      ...> into: Data.Result.pure({}) do
      ...>  x * y
      ...> end
      Data.Result.error(2)
  """

  @type t :: %__MODULE__{}

  def __struct__ do
    %{
      __struct__: __MODULE__,
      ok: nil,
      error: nil,
    }
  end

  def __struct__(kv) do
    case kv do
      [ok: x] -> %{__struct__: __MODULE__, ok: x}
      [error: x] -> %{__struct__: __MODULE__, error: x}
    end
  end

  use ComputationExpression, debug: false

  @doc """
  Abstracts away the representation of the ok constructor.
  """
  defmacro ok(x), do: quote(do: %unquote(__MODULE__){ok: unquote(x)})

  @doc """
  Abstracts away the representation of the error constructor.
  """
  defmacro error(x), do: quote(do: %unquote(__MODULE__){error: unquote(x)})

  @doc """
  Converts a simple ok / error 2-tuple into a `Result.t`

      iex> Data.Result.from_raw({:ok, 1})
      Data.Result.ok(1)
      iex> Data.Result.from_raw({:error, 2})
      Data.Result.error(2)
  """
  def from_raw({:ok, x}), do: ok(x)
  def from_raw({:error, x}), do: error(x)

  @doc """
  Converts a `Result.t` into a simple ok / error 2-tuple

      iex> Data.Result.to_raw(Data.Result.ok(1))
      {:ok, 1}
      iex> Data.Result.to_raw(Data.Result.error(2))
      {:error, 2}
  """
  def to_raw(ok(x)), do: {:ok, x}
  def to_raw(error(x)), do: {:error, x}

  @doc """
  Case analysis for the Result type.
  Applies the first function in case of an error.
  Applies the secund function in case of an ok.
  Returns the result of the application.

      iex> Data.Result.ok(0) |> Data.Result.either(fn x -> x - 1 end, fn x -> x + 1 end)
      1
      iex> Data.Result.error(0) |> Data.Result.either(fn x -> x - 1 end, fn x -> x + 1 end)
      -1
  """
  def either(error(a), f, _), do: f.(a)
  def either(ok(b), _, g), do: g.(b)

  @doc """
  Lift a value into a result.
  Equivalent to using `ok/1` directly, but you don't need to require the module.

  This should be viewed as placing a value into a successful context. Allowing
  further work on it whithin the workflow.

  Also part of a pattern.
  Also equivalent to `Enum.into/2`

      iex> Data.Result.pure({})
      Data.Result.ok({})
  """
  def pure(x), do: ok(x)

  @doc """
  Applies the function in case of an ok, leave the error untouched otherwise.
  This is the mose basic representation of the workflow defined by `Result`.

  This should be viewed as applying a function only in successful context,
  just like using `Enum.map/2` on a list should be viewed as applying a function on
  multiple possible values.

  Also part of a pattern.

      iex> Data.Result.ok(0) |> Data.Result.map(fn x -> x + 1 end)
      Data.Result.ok(1)
      iex> Data.Result.error(0) |> Data.Result.map(fn x -> x + 1 end)
      Data.Result.error(0)
  """
  def map(ok(x), f), do: ok(f.(x))
  def map(error(y), _), do: error(y)

  @doc """
  This is the same as map, but allows to transform the data contained inside the error.

  This should be viewed as way to do transformation on data without touching the workflow
  directed by the `Result`.
  Mostly useful when we want to normalize an error's content.

      iex> Data.Result.ok(0) |> Data.Result.bimap(fn {kind, payload, stacktrace} -> Exception.format(kind, payload, stacktrace) end, fn x -> x + 1 end)
      Data.Result.ok(1)
      iex> Data.Result.error({:error, :there_was_an_error, []}) |> Data.Result.bimap(fn {kind, payload, stacktrace} -> Exception.format(kind, payload, stacktrace) end, fn x -> x + 1 end)
      Data.Result.error("** (ErlangError) Erlang error: :there_was_an_error")
  """
  def bimap(error(a), f, _), do: error(f.(a))
  def bimap(ok(b), _, g), do: ok(g.(b))

  @doc """
  The composition of `map/2` and `join/1`.
  The bread and butter of the workflow defined by `Result`.
  This allows you to chain functions that return themselves `Result`s.

  This should be viewed as applying a function only in a successful context,
  but the context may change depending on the result of the function, and once we encounter an error,
  we may not go back to a successful one without external help.
  Just like using `Enum.flat_map/2` on a list should be viewed as applying a function
  on multiple possible values, but the amount a possible values may change overall.

  Also part of a pattern.

      iex> succeed = fn x -> Data.Result.pure(x * 10) end
      iex> fail = fn x -> Data.Result.error(x / 10) end
      iex> val = Data.Result.pure(1)
      iex> val |> Data.Result.bind(succeed) |> Data.Result.bind(succeed)
      Data.Result.ok(100)
      iex> val |> Data.Result.bind(fail) |> Data.Result.bind(succeed)
      Data.Result.error(0.1)
      iex> val |> Data.Result.bind(fail) |> Data.Result.bind(succeed)
      iex> Data.Result.error(:nada) |> Data.Result.bind(succeed) |> Data.Result.bind(succeed)
      Data.Result.error(:nada)
  """
  def bind(ok(x), f), do: f.(x)
  def bind(error(_) = y, _), do: y

  @doc false
  # For the computation expression builder
  def return(x), do: pure(x)

  @doc """
  Allows you to collaps nested `ok`s

  This is rarely used as `bind/2` will mostly be used instead of `map/2`.
  This should be viewed as merging two level of Result into one, where only both being
  successful will result in a successful context.
  Just like using `Enum.concat/1` on a list should be viewed as merging two level
  of possible values into one level, and merging empty lists won't produce values.

      iex> Data.Result.join(Data.Result.pure(Data.Result.pure(100)))
      Data.Result.ok(100)
      iex> Data.Result.join(Data.Result.error(100))
      Data.Result.error(100)

      iex> succeed = fn x -> Data.Result.pure(x * 10) end
      iex> fail = fn x -> Data.Result.error(x / 10) end
      iex> val = Data.Result.pure(1)
      iex> val |> Data.Result.map(succeed) |> Data.Result.join()
      Data.Result.ok(10)
      iex> val |> Data.Result.map(fail) |> Data.Result.join()
      Data.Result.error(0.1)
      iex> Data.Result.error(:nada) |> Data.Result.map(succeed) |> Data.Result.join()
      Data.Result.error(:nada)
  """
  def join(ok(x)), do: x
  def join(error(_) = y), do: y

  @doc """
  Forcefully extract a value from an `ok`.
  Will crash on `error`s.

      iex> Data.Result.from_ok!(Data.Result.pure(13))
      13
  """
  def from_ok!(ok(x)), do: x

  @doc """
  Forcefully extract a value from an `error`.
  Will crash on `ok`s.

      iex> Data.Result.from_error!(Data.Result.error(:bonk))
      :bonk
  """
  def from_error!(error(x)), do: x

  @doc """
  Convert a list of `Result`s into a `Result` of a list.
  This follows the workflow defined by `Result`, so if an `error` is
  encountered the computation stops and this `error` is returned instead.

  This should be viewed as transposing the workflow brought by a list with
  the workflow brought by `Result`.

      iex> import Data.Result
      iex> sequence([ok(1), ok(2), ok(3)])
      ok([1, 2, 3])
      iex> sequence([ok(1), error(2), ok(3)])
      error(2)
      iex> sequence([ok(1), error(2), error(3)])
      error(2)
  """
  def sequence(mxs), do: mapM(mxs, & &1)

  @doc """
  Maps a function returning a `Result` to a list of values and converts it
  into a `Result` of a list. As `sequence/1`, stops on the first `error` encountered.

  Just as `sequence/1`, this should be viewed as wanting to use the list workflow of dealing with multiple
  possible values, with the `Result` workflow of keeping computation within a successful context.
  The mapping function will decide whether to keep going with the multiple values or not.

      iex> [1, 2, 3] |> Data.Result.map_m(&Data.Result.pure/1)
      Data.Result.ok([1, 2, 3])
      iex> [1, 2, 3] |> Data.Result.map_m(fn x when rem(x, 2) == 0 -> Data.Result.error(x) ; x -> Data.Result.pure(x) end)
      Data.Result.error(2)
  """
  #def map_m(as, f) do
  #  k = fn a, acc ->
  #    acc |> bind(fn xs ->
  #      f.(a) |> bind(fn x ->
  #        pure([x | xs])
  #      end)
  #    end)
  #  end

  #  List.foldr(as, pure([]), k)
  #end

  #def map_m(as, f) do
  #  reducer = fn x, acc -> bind(f.(x), fn y -> pure([y | acc]) end) end

  #  foldl_m(as, [], reducer)
  #  |> map(&Enum.reverse/1)
  #end

  def mapM([], _), do: pure([])
  def mapM([x | xs], f) do
    compute do
      let! y = f.(x)
      let! ys = mapM(xs, f)
      pure([y | ys])
    end
  end

  @doc """
  Reduce on a list of values, but stops at the first error encountered, as defined by
  the workflow of `Result`.

  This should be viewed in the same manner as `map_m/2`. This is an equivalent to `Enum.reduce_while/3`
  where the `Result` workflow decides whether to keep going with the rest of the reduction.

      iex> [1, 2, 3] |> Data.Result.foldl_m(0, &Data.Result.pure(&1 + &2))
      Data.Result.ok(6)
      iex> [1, 2, 3] |> Data.Result.foldl_m(0, fn x, _acc when rem(x, 2) == 0 -> Data.Result.error(x) ; x, acc -> Data.Result.pure(x + acc) end)
      Data.Result.error(2)
  """
  # foldl_m :: (Monad m) => [a], b, (a, b -> m b) -> m b
  #def foldl_m(xs, z0, f) do
  #  c = fn x, k -> fn acc -> f.(x, acc) |> bind(k) end end
  #  List.foldr(xs, &pure/1, c).(z0)
  #end
  def reduceM(xs, z0, f) do
    Enum.reduce(xs, pure(z0), fn x, macc -> bind(macc, fn acc -> f.(x, acc) end) end)
  end
end

defimpl Inspect, for: Data.Result do
  alias Data.Result
  require Result

  def inspect(Result.ok(x), opts), do: Inspect.Algebra.concat(["Data.Result.ok(", Inspect.Algebra.to_doc(x, opts), ")"])
  def inspect(Result.error(x), opts), do: Inspect.Algebra.concat(["Data.Result.error(", Inspect.Algebra.to_doc(x, opts), ")"])
end

defimpl Enumerable, for: Data.Result do
  alias Data.Result
  require Result

  def reduce(_r, {:halt, acc} = _cc, _f) do
    #_ = IO.puts("init #{inspect(__MODULE__)}.reduce(#{inspect(r)}, #{inspect(cc)}, #{inspect(f)})")
    {:halted, acc}
  end

  #def reduce(r, {:suspend, acc} = cc, f) do
  #  _ = IO.puts("init #{inspect(__MODULE__)}.reduce(#{inspect(r)}, #{inspect(cc)}, #{inspect(f)})")
  #  {:suspended, acc, &IO.inspect(&1, label: "direct suspension restarted")}
  #end

  #def reduce(r, {:cont, acc} = cc, f) do
  #  _ = IO.puts("bind #{inspect(__MODULE__)}.reduce(#{inspect(r)}, #{inspect(cc)}, #{inspect(f)})")
  #  r |> Data.Result.bind(fn x ->
  #  case f.(x, acc) do
  #    {:halt, y} -> {:halted, y}
  #    {:cont, y} -> {:done, y}
  #    {:suspend, y} -> {:suspended, y, &IO.inspect(&1, label: "suspension restarted")}
  #  end
  #  end)
  #end

  def reduce(Result.ok(x) = _r, {:cont, acc} = _cc, f) do
    #_ = IO.puts("init #{inspect(__MODULE__)}.reduce(#{inspect(r)}, #{inspect(cc)}, #{inspect(f)})")
    case f.(x, acc) do
      {:halt, y} -> {:halted, y}
      {:cont, y} -> {:done, y}
      {:suspend, y} -> {:suspended, y, &IO.inspect(&1, label: "suspension restarted")}
    end
  end

  def reduce(Result.error(_) = r, {:cont, _acc} = _cc, _f) do
    #_ = IO.puts("init #{inspect(__MODULE__)}.reduce(#{inspect(r)}, #{inspect(cc)}, #{inspect(f)})")
    {:halt, r}
  end

  def count(Result.error(_)), do: {:ok, 0}
  def count(Result.ok(_)), do: {:ok, 1}

  def member?(Result.error(_), _), do: {:ok, false}
  def member?(Result.ok(x), y), do: {:ok, x === y}

  def slice(_), do: {:error, __MODULE__}
end

defimpl Collectable, for: Data.Result do
  alias Data.Result
  require Result

  def into(Result.error(_)) do
    raise ArgumentError, "Cannot use Result.error(_) with Enum.into/2,3"
  end

  def into(Result.ok(_) = x) do
    collector_fun = fn
      acc, {:cont, elem} ->
        Result.map(acc, fn _ -> elem end)

      acc, :done ->
        acc

      _map_set_acc, :halt ->
        :ok
    end

    initial_acc = x

    {initial_acc, collector_fun}
  end
end
