defmodule Monad.State do
  @enforce_keys [:run_state]
  defstruct [:run_state]

  # (s -> (s, a)) -> State s a
  def new(x), do: %__MODULE__{run_state: x}

  # State s s
  def get do
    new(fn s -> {s, s} end)
  end

  # s -> State s ()
  def put(s) do
    new(fn _ -> {s, {}} end)
  end

  # (s -> s) -> State s ()
  def modify(f) do
    new(fn s -> {f.(s), {}} end)
  end

  # a -> State s a
  def pure(x), do: new(fn s -> {s, x} end)

  # State s a -> (a -> b) -> State s b
  def map(ma, f) do
    new(fn s ->
      {s, a} = ma.run_state.(s)
      {s, f.(a)}
    end)
  end

  def ap(mf, ma) do
    new(fn s ->
      {s, f} = mf.run_state.(s)
      {s, a} = ma.run_state.(s)
      {s, f.(a)}
    end)
  end

  # State s (State s a) -> State s a
  def join(mma) do
    new(fn s ->
      {s, ma} = mma.run_state.(s)
      ma.run_state.(s)
    end)
  end

  # State s a -> (a -> State s b) -> State s b
  def bind(ma, f) do
    new(fn s ->
      {s, a} = ma.run_state.(s)
      f.(a).run_state.(s)
    end)
  end
end
