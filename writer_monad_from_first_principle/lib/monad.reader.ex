defmodule Monad.Reader do
  @enforce_keys [:run_reader]
  defstruct [:run_reader]

  # (cfg -> a) -> Reader cfg a
  def new(x), do: %__MODULE__{run_reader: x}

  # Reader cfg cfg
  def ask do
    new(fn cfg -> cfg end)
  end

  # (cfg -> a) -> Reader cfg a
  def asks(f) do
    new(f)
  end

  # (cfg -> cfg') -> Reader cfg' a -> Reader cfg a
  def local(f, ma) do
    new(fn cfg ->
      ma.run_reader.(f.(cfg))
    end)
  end

  def local2(f, ma) do
    require Monad
    Monad.m __MODULE__ do
      cfg <- ask()
      pure ma.run_reader.(f.(cfg))
    end
  end

  # Reader cfg a -> (a -> b) -> Reader cfg b
  def map(ma, f) do
    new(fn cfg ->
      x = ma.run_reader.(cfg)
      f.(x)
    end)
  end

  # a -> Reader cfg a
  def pure(x), do: new(fn _cfg -> x end)

  # Reader cfg (a -> b) -> Reader cfg a -> Reader cfg b
  def ap(mf, ma) do
    new(fn cfg ->
      f = mf.run_reader.(cfg)
      a = ma.run_reader.(cfg)
      f.(a)
    end)
  end

  # Reader cfg (Reader cfg a)
  def join(mma) do
    new(fn cfg ->
      ma = mma.run_reader.(cfg)
      ma.run_reader.(cfg)
    end)
  end

  # Reader cfg a -> (a -> Reader cfg b) -> Reader cfg b
  def bind(ma, f) do
    new(fn cfg ->
      x = ma.run_reader.(cfg)
      f.(x).run_reader.(cfg)
    end)
  end
end
