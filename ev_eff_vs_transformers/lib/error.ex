defmodule Error do
  def pure(xs, reduce) do
    pure_run_error(xs, reduce)
  end

  def ev_maybe(xs, reduce) do
    Eff.runEff(Eff.Exception.exceptMaybe(ev_run_error(xs, reduce)))
  end

  def ev_either(xs, reduce) do
    Eff.runEff(Eff.Exception.exceptEither(ev_run_error(xs, reduce)))
  end

  def ev_default(xs, reduce) do
    Eff.runEff(Eff.Exception.exceptDefault(0, ev_run_error(xs, reduce)))
  end

  def trans(xs, reduce) do
    trans_run_error(xs, reduce)
  end

  def freer(xs, reduce) do
    Freer.run(Freer.Exception.runException(freer_run_error(xs, reduce)))
  end

  def freer_q(xs, reduce) do
    FreerQ.run(FreerQ.Exception.runException(freer_q_run_error(xs, reduce)))
  end

  @doc false
  def pure_run_error(xs, reduce) do
    f = fn
      0, _acc -> 0
      _x, 0 -> 0
      x, acc -> acc * x
    end
    reduce.(xs, 1, f)
  end

  @doc false
  def ev_run_error(xs, reduce) do
    use Eff
    f = fn
      0, _acc -> perform Eff.Exception.throw_error(), 0
      x, acc -> Eff.pure(acc * x)
    end
    reduce.(xs, 1, f)
  end

  @doc false
  def trans_run_error(xs, reduce) do
    require Base.Result
    f = fn
      0, _acc -> Base.Result.error(0)
      x, acc -> Base.Result.pure(acc * x)
    end
    reduce.(xs, 1, f)
  end

  @doc false
  def freer_run_error(xs, reduce) do
    require Freer
    f = fn
      0, _acc -> Freer.Exception.throw_error(0)
      x, acc -> Freer.pure(acc * x)
    end
    reduce.(xs, 1, f)
  end

  @doc false
  def freer_q_run_error(xs, reduce) do
    require FreerQ
    f = fn
      0, _acc -> FreerQ.Exception.throw_error(0)
      x, acc -> FreerQ.pure(acc * x)
    end
    reduce.(xs, 1, f)
  end
end
