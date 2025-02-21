defmodule Parsing do
  use Eff
  use FreerQ


  def ev(input) do
    runEff(Parser.solutions(Parser.parse(input, Parser.expr())))
  end

  def freer_state(input) do
    FreerQ.run(FreerQ.Parser.solutions(FreerQ.Parser.parse_state(FreerQ.Parser.expr(), input)))
  end
end
