defmodule Count do
  import ComputationExpression

  use Eff

  require Local
  require Flocal

  def pure(n) do
    pure_run_count(n)
  end

  def ev_state(n) do
    Eff.runEff(State.state(n, ev_state_run_count()))
  end

  def ev_local(n) do
    Eff.runEff(Local.local(n, ev_local_run_count()))
  end

  #def ev_fstate(n) do
  #  Eff.runEff(Fstate.state(n, ev_fstate_run_count()))
  #end

  def ev_flocal(n) do
    Eff.runEff(Flocal.local(n, ev_flocal_run_count()))
  end

  def trans(n) do
    Wrapped.State.evalStateT(trans_run_count(), n)
  end

  def freer(n) do
    {ret, _state} = Freer.run(Freer.State.runState(freer_run_count(), n))
    ret
  end

  def freer_q(n) do
    {ret, _state} = FreerQ.run(FreerQ.State.runState(freer_q_run_count(), n))
    ret
  end

  @doc false
  def pure_run_count(0), do: 0
  def pure_run_count(n), do: pure_run_count(n - 1)

  @doc false
  def ev_state_run_count do
    m Eff do
      i <- perform State.get(), {}
      if i == 0 do
        Eff.pure(i)
      else
        m Eff do
          perform State.put(), (i - 1)
          ev_state_run_count()
        end
      end
    end
  end

  @doc false
  def ev_local_run_count do
    m Eff do
      i <- Local.localGet()
      if i == 0 do
        Eff.pure(i)
      else
        m Eff do
          Local.localPut(i - 1)
          ev_local_run_count()
        end
      end
    end
  end

  # @doc false
  # def ev_fstate_run_count do
  #   m Eff do
  #     i <- Fstate.get()
  #     if i == 0 do
  #       Eff.pure(i)
  #     else
  #       m Eff do
  #         Fstate.put(i - 1) 
  #         ev_fstate_run_count()
  #       end
  #     end
  #   end
  # end

  @doc false
  def ev_flocal_run_count do
    m Eff do
      i <- Flocal.get()
      if i == 0 do
        Eff.pure(i)
      else
        m Eff do
          Flocal.put(i - 1)
          ev_flocal_run_count()
        end
      end
    end
  end

  @doc false
  def trans_run_count do
    compute Workflow.State do
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

  @doc false
  def freer_q_run_count do
    compute Workflow.FreerQ do
      let! i = FreerQ.State.get()
      match i do
        0 -> pure i
        _ ->
          do! FreerQ.State.put(i - 1)
          pure! freer_q_run_count()
      end
    end
  end
end
