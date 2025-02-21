defmodule FreerQ.Example do
  use FreerQ.Amb
  use FreerQ.Parser

  import Bind

  require Workflow.FreerQ

  def xor do
    m Workflow.FreerQ do
      x <- FreerQ.Amb.flip()
      y <- FreerQ.Amb.flip()
      FreerQ.pure((x and not y) or (not x and y))
    end
  end

  def eager_parse_state do
    import FreerQ.Parser
    FreerQ.run(eager(parse_state(expr(), ~c'1+2*3')))
  end

  def all_parse_state do
    import FreerQ.Parser
    expr()
    |> parse_state(~c'1+2*3')
    |> solutions()
    |> FreerQ.run()
  end

  def eager_parse do
    import FreerQ.Parser
    FreerQ.run(eager(FreerQ.State.runState(parse(expr()), ~c'1+2*3')))
  end

  def all_parse do
    import FreerQ.Parser

    expr()
    |> parse()
    |> FreerQ.State.runState(~c'1+2*3')
    |> solutions()
    |> FreerQ.run()
  end
end
