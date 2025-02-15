defmodule Count5 do
  import ComputationExpression

  use Eff

  require FreerQ
  require Freer
  require Wrapped.State
  require Local
  require Flocal

  def pure(n) do
    {ret, _st} = pure_run_count_5(n)
    ret
  end

  def ev_local(n, reduce) do
    Eff.runEff(Local.local(0, ev_local_run_count_5(n, reduce)))
  end

  #def ev_flocal(n, reduce) do
  #  Eff.runEff(Flocal.local(0, ev_flocal_run_count_5(n, reduce)))
  #end

  # def ev_state(n) do
  #   Eff.runEff(State.state(0, ev_state_run_count_5(n)))
  # end

  def trans(n, reduce) do
    Wrapped.State.evalStateT(trans_run_count_5(n, reduce), 0)
  end

  def freer(n, reduce) do
    {ret, _st} = Freer.run Freer.State.runState(freer_run_count_5(n, reduce), 0)
    ret
  end

  def freer_q(n, reduce) do
    {ret, _st} = FreerQ.run FreerQ.State.runState(freer_q_run_count_5(n, reduce), 0)
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
  def ev_local_run_count_5(n, reduce) do
    range = n..0//-1
    f = fn
      x, acc when rem(x, 5) == 0 ->
        m Eff do
          i <- Local.localGet()
          Local.localPut(i + 1)
          Eff.pure(max(acc, x))
        end

      x, acc -> Eff.pure(max(acc, x))
    end
    reduce.(range, 1, f)
  end

  #@doc false
  #def ev_flocal_run_count_5(n, reduce) do
  #  range = n..0//-1
  #  f = fn
  #    x, acc when rem(x, 5) == 0 ->
  #      m Eff do
  #        i <- Flocal.get()
  #        Flocal.put(i + 1)
  #        Eff.pure(max(acc, x))
  #      end

  #    x, acc -> Eff.pure(max(acc, x))
  #  end
  #  reduce.(range, 1, f)
  #end

  # @doc false
  # def ev_state_run_count_5(n) do
  #   range = n..0//-1
  #   f = fn
  #     x, acc when rem(x, 5) == 0 ->
  #       m Eff do
  #         i <- perform State.get(), {}
  #         perform State.put(), (i + 1)
  #         Eff.pure(max(acc, x))
  #       end

  #     x, acc -> Eff.pure(max(acc, x))
  #   end
  #   reduceMEff(range, 1, f)
  # end

  @doc false
  def trans_run_count_5(n, reduce) do
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
    reduce.(range, 1, f)
  end

  @doc false
  def freer_run_count_5(n, reduce) do
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
    reduce.(range, 1, f)
  end

  @doc false
  def freer_q_run_count_5(n, reduce) do
    range = n..0//-1
    f = fn
      x, acc when rem(x, 5) == 0 ->
        compute Workflow.FreerQ do
          let! i = FreerQ.State.get()
          do! FreerQ.State.put(i + 1)
          pure max(acc, x)
        end

      x, acc -> FreerQ.pure(max(acc, x))
    end
    reduce.(range, 1, f)
  end
end
