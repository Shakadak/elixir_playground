defmodule Maybe do
  import Data

  data __MODULE__ do
    just(a)
    nothing
  end

  def from_maybe(_, just(x)), do: x
  def from_maybe(default, nothing()), do: default
end
