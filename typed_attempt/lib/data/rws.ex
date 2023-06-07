defmodule Data.RWS do
  require Control.RwsT

  Control.RwsT.mk(Data.Identity)
end
