defmodule Data.ResultRWS do
  require Control.RwsT

  Control.RwsT.mk(Data.Result)


  def throwError(x), do: __MODULE__.lift(Data.Result.error(x))
end
