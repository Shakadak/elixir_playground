defmodule Data.Identity do
  @enforce_keys [:runIdentity]
  defstruct [:runIdentity]

  defmacro identity(x) do
    quote do %unquote(__MODULE__){runIdentity: unquote(x)} end
  end

  def map(identity(x), f), do: identity(f.(x))

  def pure(x), do: identity(x)

  def ap(identity(f), identity(x)), do: identity(f.(x))

  def liftA2(f, identity(x), identity(y)), do: identity(f.(x, y))

  def bind(identity(x), f), do: f.(x)
end
