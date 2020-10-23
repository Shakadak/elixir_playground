defmodule Monad.State do
  @enforce_keys [:run_state]
  defstruct [:run_state]

  def get do
  end

  def put(_s) do
  end

  def modify(_f) do
  end
end
