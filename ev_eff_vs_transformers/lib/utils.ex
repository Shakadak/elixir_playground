defmodule Utils do
  use Eff

  def reduceMEff(xs, z0, f) do
    Enum.reduce(xs, Eff.pure(z0), fn x, macc ->
      Eff.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMTrans(xs, z0, f) do
    Enum.reduce(xs, Wrapped.State.pure(z0), fn x, macc ->
      require Wrapped.State
      Wrapped.State.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMTransResult(xs, z0, f) do
    require Base.Result
    Enum.reduce(xs, Base.Result.pure(z0), fn x, macc ->
      Base.Result.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end

  def reduceMFreer(xs, z0, f) do
    require Freer
    Enum.reduce(xs, Freer.pure(z0), fn x, macc ->
      Freer.bind(macc, fn acc -> f.(x, acc) end)
    end)
  end
end
