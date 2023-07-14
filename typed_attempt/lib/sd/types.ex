defmodule TVar do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro tv(x), do: quote(do: %unquote(__MODULE__){@: unquote(x)})
end

defimpl Inspect, for: TVar do
  def inspect(%{@: x}, _opts), do: x
end

defmodule Scheme do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro forall(tvars, type), do: quote(do: %unquote(__MODULE__){@: {unquote(tvars), unquote(type)}})
end

defmodule TypeEnv do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro typeEnv(x), do: quote(do: %unquote(__MODULE__){@: unquote(x)})

  def extend(typeEnv(env), {x, s}), do: typeEnv(Map.put(env, x, s))

  def empty, do: typeEnv(Map.new())

  def remove(typeEnv(env), var), do: typeEnv(Map.delete(env, var))
end

defmodule Subst do
  def nullSubst, do: %{}

  def compose(s1, s2) do
    s2b = Map.new(s2, fn {k, v} -> {k, Substitutable.apply(v, s1)} end)
    Map.merge(s1, s2b)
  end
end

defprotocol Substitutable do
  def apply(a, subst)

  def ftv(a)
end

defimpl Substitutable, for: Type do
  import Type

  def apply(tcon(a), _), do: tcon(a)
  def apply(tvar(a) = t, s), do: Map.get(s, a, t)
  def apply(t1 |> tarr(t2), s), do: Substitutable.apply(t1, s) |> tarr(Substitutable.apply(t2, s))

  def ftv(tcon(_)), do: MapSet.new()
  def ftv(tvar(a)), do: MapSet.new([a])
  def ftv(t1 |> tarr(t2)), do: Substitutable.ftv(t1) |> MapSet.union(ftv(t2))
end

defimpl Substitutable, for: Scheme do
  import Scheme

  def apply(forall(as, t), s) do
    s2 = Enum.reduce(as, s, &Map.delete(&2, &1))
    forall(as, Substitutable.apply(t, s2))
  end

  def ftv(forall(as, t)), do: Substitutable.ftv(t) |> MapSet.difference(MapSet.new(as))
end

defimpl Substitutable, for: Tuple do
   def apply({t1, t2}, s), do: {Substitutable.apply(t1, s), Substitutable.apply(t2, s)}
   def ftv({t1, t2}), do: Substitutable.ftv(t1) |> MapSet.union(Substitutable.ftv(t2))
end

defimpl Substitutable, for: List do
  def apply(xs, s), do: Enum.map(xs, &Substitutable.apply(&1, s))

  def ftv(xs), do: Enum.reduce(xs, MapSet.new(), &MapSet.union(Substitutable.ftv(&1), &2))
end

defimpl Substitutable, for: TypeEnv do
  import TypeEnv

  def apply(typeEnv(env), s), do: typeEnv(Map.new(env, fn {k, v} -> {k, Substitutable.apply(v, s)} end))

  def ftv(typeEnv(env)), do: Substitutable.ftv(Map.values(env))
end
