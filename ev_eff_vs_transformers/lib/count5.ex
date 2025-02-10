defmodule Count5 do
  import Utils

  def pure(n) do
    {ret, _st} = pure_run_count_5(n)
    ret
  end

  def ev_ets(n) do
    Eff.runEff(State.state(0, ev_run_count_5(n)))
  end

  def ev_fun(n) do
    Eff.runEff(State.state2(0, ev_run_count_5(n)))
  end

  def trans(n) do
    Wrapped.State.evalStateT(trans_run_count_5(n), 0)
  end

  def freer(n) do
    {ret, _st} = Freer.run Freer.State.runState(freer_run_count_5(n), 0)
    ret
  end

  @doc false
  def pure_run_count_5(n) do
    range = n..0//-1
    Enum.reduce(range, {1, 0}, fn
      x, {acc, state} when rem(x, 5) == 0 -> {max(acc, x), state + 1}
      x, {acc, state} -> {max(acc, x), state}
    end)
  end

  @doc false
  def ev_run_count_5(n) do
    use Eff
    range = n..0//-1
    f = fn
      x, acc when rem(x, 5) == 0 ->
        m Eff do
          i <- perform State.get(), {}
          perform State.put(), (i + 1)
          Eff.pure(max(acc, x))
        end

      x, acc -> Eff.pure(max(acc, x))
    end
    reduceMEff(range, 1, f)
  end

  @doc false
  def trans_run_count_5(n) do
    import ComputationExpression
    require Wrapped.State
    range = n..0//-1
    f = fn
      x, acc when rem(x, 5) == 0 ->
        compute Workflow.State do
          let! i = Wrapped.State.get()
          do! Wrapped.State.put(i + 1)
          pure max(acc, x)
        end

      x, acc -> Wrapped.State.pure(max(acc, x))
    end
    reduceMTrans(range, 1, f)
  end

  @doc false
  def freer_run_count_5(n) do
    import ComputationExpression
    require Freer
    range = n..0//-1
    f = fn
      x, acc when rem(x, 5) == 0 ->
        compute Workflow.Freer do
          let! i = Freer.State.get()
          do! Freer.State.put(i + 1)
          pure max(acc, x)
        end

      x, acc -> Freer.pure(max(acc, x))
    end
    reduceMFreer(range, 1, f)
  end
end
