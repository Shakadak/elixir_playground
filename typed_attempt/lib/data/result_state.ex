defmodule Data.ResultState do
  require Control.StateT

  Control.StateT.mk(Data.Result)

  def throwError(x), do: __MODULE__.lift(Data.Result.error(x))
end
