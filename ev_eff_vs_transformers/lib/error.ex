defmodule Error do
  import Utils

  def pure(xs) do
    pure_run_error(xs)
  end

  def ev_maybe(xs) do
    Eff.runEff(Eff.Exception.exceptMaybe(ev_run_error(xs)))
  end

  def ev_either(xs) do
    Eff.runEff(Eff.Exception.exceptEither(ev_run_error(xs)))
  end

  def ev_default(xs) do
    Eff.runEff(Eff.Exception.exceptDefault(0, ev_run_error(xs)))
  end

  def trans(xs) do
    trans_run_error(xs)
  end

  def freer(xs) do
    Freer.run(Freer.Exception.runException(freer_run_error(xs)))
  end

  @doc false
  def pure_run_error(xs) do
    f = fn
      0, _acc -> 0
      _x, 0 -> 0
      x, acc -> acc * x
    end
    Enum.reduce(xs, 1, f)
  end

  @doc false
  def ev_run_error(xs) do
    use Eff
    f = fn
      0, _acc -> perform Eff.Exception.throw_error(), 0
      x, acc -> Eff.pure(acc * x)
    end
    reduceMEff(xs, 1, f)
  end

  @doc false
  def trans_run_error(xs) do
    require Base.Result
    f = fn
      0, _acc -> Base.Result.error(0)
      x, acc -> Base.Result.pure(acc * x)
    end
    reduceMTransResult(xs, 1, f)
  end

  @doc false
  def freer_run_error(xs) do
    require Freer
    f = fn
      0, _acc -> Freer.Exception.throw_error(0)
      x, acc -> Freer.pure(acc * x)
    end
    reduceMFreer(xs, 1, f)
  end
end
