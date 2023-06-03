alias ComputationExpression, as: CE
require CE

m = CE.compute Data.ResultRWS do     
  let! cfg = Data.ResultRWS.ask()
  Data.ResultRWS.tell([cfg + 1]) 
  pure cfg
end

Data.ResultRWS.runRwsT(m, 0, %{})
|> IO.inspect()
