defmodule FreerQ.Example do
  use FreerQ.Amb

  import Bind

  require Workflow.FreerQ

  def xor do
    m Workflow.FreerQ do
      x <- FreerQ.Amb.flip()
      y <- FreerQ.Amb.flip()
      FreerQ.pure((x and not y) or (not x and y))
    end
  end
end
