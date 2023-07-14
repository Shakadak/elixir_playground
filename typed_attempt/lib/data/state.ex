defmodule Data.State do
  require Control.StateT

  Control.StateT.mk(Data.Identity)
end
