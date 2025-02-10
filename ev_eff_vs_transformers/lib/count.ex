defmodule Count do
  import ComputationExpression

  def pure(n) do
    pure_run_count(n)
  end

  def ev_ets(n) do
    Eff.runEff(State.state(n, ev_run_count()))
  end

  def ev_fun(n) do
    Eff.runEff(State.state2(n, ev_run_count()))
  end

  def trans(n) do
    Wrapped.State.evalStateT(trans_run_count(), n)
  end

  def freer(n) do
    {ret, _state} = Freer.run(Freer.State.runState(freer_run_count(), n))
    ret
  end

  @doc false
  def pure_run_count(0), do: 0
  def pure_run_count(n), do: pure_run_count(n - 1)

  def ev_run_count do
    use Eff
    m Eff do
      i <- perform State.get(), {}
      if i == 0 do
        Eff.pure(i)
      else
        m Eff do
          perform State.put(), (i - 1)
          ev_run_count()
        end
      end
    end
  end

  @doc false
  def trans_run_count do
    compute Workflow.State, debug: true do
      let! i = Wrapped.State.get()
      match i do
        0 -> pure i
        _ ->
          do! Wrapped.State.put(i - 1)
          pure! trans_run_count()
      end
    end
  end

  @doc false
  def freer_run_count do
    import ComputationExpression
    compute Workflow.Freer do
      let! i = Freer.State.get()
      match i do
        0 -> pure i
        _ ->
          do! Freer.State.put(i - 1)
          pure! freer_run_count()
      end
    end
  end
end
