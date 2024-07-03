defmodule Wrapped.ListState do
  require Transformer.StateT

  Transformer.StateT.mk(Local.List)
end
