defmodule Local do
  @enforce_keys [
    :lget,
    :lput,
  ]
  defstruct @enforce_keys 

  def lget, do: fn {} -> {:foret} end
  def lput, do: fn {} -> {:noire} end
end
