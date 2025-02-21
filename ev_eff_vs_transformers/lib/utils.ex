defmodule Utils do
  use Eff
  require Wrapped.State
  require Base.Result
  require FreerSeq
  require FreerQ

  def reduceMEff(xs, z0, f) do
    Enum.reduce(xs, Eff.pure(z0), fn x, macc ->
      Eff.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def foldMEff([], z0, _f) do
    Eff.pure(z0)
  end

  def foldMEff([head | tail], z0, f) do
    macc = f.(head, z0)
    Eff.bind(macc, fn acc -> foldMEff(tail, acc, f) end)
  end

  def rreduceMEff(xs, z0, f) do
    Enumerable.reduce(xs, {:suspend, Eff.pure(z0)}, fn x, acc ->
      {:suspend, f.(x, acc)}
    end)
    |> do_rreduceMEff()
  end

  def do_rreduceMEff({:suspended, action, reducer}) do
    Eff.bind(action, fn acc ->
      reducer.({:cont, acc})
      |> do_rreduceMEff()
    end)
  end

  def do_rreduceMEff({:done, value}) do
    Eff.pure(value)
  end

  def reduceMTrans(xs, z0, f) do
    Enum.reduce(xs, Wrapped.State.pure(z0), fn x, macc ->
      Wrapped.State.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMTransResult(xs, z0, f) do
    Enum.reduce(xs, Base.Result.pure(z0), fn x, macc ->
      Base.Result.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMFreerSeq(xs, z0, f) do
    Enum.reduce(xs, FreerSeq.pure(z0), fn x, macc ->
      FreerSeq.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMFreerQ(xs, z0, f) do
    Enum.reduce(xs, FreerQ.pure(z0), fn x, macc ->
      FreerQ.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def foldMFreerQ([], z0, _f) do
    FreerQ.pure(z0)
  end

  def foldMFreerQ([head | tail], z0, f) do
    macc = f.(head, z0)
    FreerQ.bind(macc, fn acc -> foldMFreerQ(tail, acc, f) end)
  end

  def rreduceMFreerQ(xs, z0, f) do
    Enumerable.reduce(xs, {:suspend, FreerQ.pure(z0)}, fn x, acc ->
      {:suspend, f.(x, acc)}
    end)
    |> do_rreduceMFreerQ()
  end

  def do_rreduceMFreerQ({:suspended, action, reducer}) do
    FreerQ.bind(action, fn acc ->
      reducer.({:cont, acc})
      |> do_rreduceMFreerQ()
    end)
  end

  def do_rreduceMFreerQ({:done, value}) do
    FreerQ.pure(value)
  end
end
