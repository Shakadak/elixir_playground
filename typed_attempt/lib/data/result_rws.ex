defmodule Data.ResultRWS do
  require Control.RwsT

  Control.RwsT.mk(Data.Result)
end
