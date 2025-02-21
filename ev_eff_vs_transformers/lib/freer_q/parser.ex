defmodule FreerQ.Parser do
  require FreerQ.Amb
  import FreerQ
  import Bind

  require FreerQ.State
  require Workflow.FreerQ

  defmacro __using__([]) do
    quote do
      require FreerQ
      require unquote(__MODULE__)
    end
  end

  defmacro satisfy(p), do: quote(do: FreerQ.op({Satisfy, unquote(p)}))

  def parse_state(action, input) do
    ret = &pure({&1, &2})
    handle_relay_state(action, input, ret, fn
      s, {Satisfy, p}, k, _ ->
        case p.(s) do
          Nothing -> FreerQ.Exception.throw_error({})
          {Just, {x, rest}} -> k.(x, rest)
        end

      _, _, _, next -> next.()
    end)
  end

  def parse(action) do
    handle_relay(action, &pure/1, fn
      {Satisfy, p}, k, _ ->
        m Workflow.FreerQ do
          input <- FreerQ.State.get()
          case p.(input) do
            Nothing -> FreerQ.Exception.throw_error({})
            {Just, {x, rest}} -> m Workflow.FreerQ do
              FreerQ.State.put(rest)
              k.(x)
            end
          end
        end

      _, _, next -> next.()
    end)
  end

  def choice(p1, p2) do
    m Workflow.FreerQ do
      b <- FreerQ.Amb.flip()
      if b do p1 else p2 end
    end
  end

  def many(p) do
    choice(many1(p), pure([]))
  end

  def many1(p) do
    m Workflow.FreerQ do
      x <- p
      xs <- many(p)
      pure([x | xs])
    end
  end

  ### --------------------

  def symbol(c) do
    satisfy fn
      [d | rest] when d == c -> {Just, {c, rest}}
      _ -> Nothing
    end
  end

  def digit do
    satisfy fn
      [d | rest] when d in ?0..?9 -> {Just, {d - ?0, rest}}
      _ -> Nothing
    end
  end

  def expr do
    choice(m Workflow.FreerQ do
      i <- term() ; symbol(?+) ; j <- term()
      pure(i + j)
    end, term())
  end

  def term do
    choice(m Workflow.FreerQ do
      i <- factor() ; symbol(?*) ; j <- factor()
      pure(i * j)
    end, factor())
  end

  def factor do
    choice(m Workflow.FreerQ do
      symbol(?() ; i <- expr() ; symbol(?))
      pure(i)
    end, number())
  end

  def number do
    m Workflow.FreerQ do
      xs <- many1(digit())
      pure(Enum.reduce(xs, 0, fn d, n -> 10 * n + d end))
    end
  end

  def catMaybes(xs) do
    Enum.flat_map(xs, fn
      {Just, x} -> [x]
      Nothing -> []
    end)
  end

  def solutions(action) do
    action
    |> FreerQ.Exception.toMaybe()
    |> FreerQ.Amb.allResults()
    |> map(&catMaybes/1)
  end

  def eager(action) do
    FreerQ.Amb.firstResult(FreerQ.Exception.toMaybe(action))
  end
end
