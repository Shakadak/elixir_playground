defmodule Parsing do
  use Eff
  use FreerQ


  def ev(input) do
    runEff(Parser.solutions(Parser.parse(input, Parser.expr())))
  end

  def freer(input) do
    FreerQ.run(Freer.Parser.solutions(Freer.Parser.parse(input, Freer.Example.expr())))
  end
end
