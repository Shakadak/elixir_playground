defmodule Tunny.Eff do
  @enforce_keys [:unsafe_un_eff]
  defstruct @enforce_keys

  defmacro unsafe_mk_eff(action) do
    quote do
      %unquote(__MODULE__){unsafe_un_eff: unquote(action)}
    end
  end

  def map(unsafe_mk_eff(x), f), do: unsafe_mk_eff(f.(x))
  def bind(unsafe_mk_eff(x), f), do: f.(x)
  def pure(x), do: unsafe_mk_eff(x)
end

defmodule Tunny.Eff.Exception do
  import Tunny.Eff

  @enforce_keys [:unsafe_un_mk_exception]
  defstruct @enforce_keys

  defmacro unsafe_mk_exception(action) do
    quote do
      %unquote(__MODULE__){unsafe_un_mk_exception: unquote(action)}
    end
  end

  def try(k) do
    unsafe_mk_eff(with_scoped_exception_(fn throw_ ->
      k.(unsafe_mk_exception(throw_)).unsafe_un_eff
    end))
  end

  def with_scoped_exception_(k) do
    fresh = :erlang.unique_integer([:positive])
    tryJust(fn -> k.(fn e -> throwIO({MyException, e, fresh}) end) end, fn
      {MyException, e, tag} -> if tag == fresh do {Just, e} else Nothing end
    end)
  end

  def tryJust(action, predicate) do
    catchJust(predicate, {Right, action}, &{Left, &1})
  end

  def catchJust(predicate, action, handler) do
    case predicate.(action) do
      Nothing -> :"?"
      {Just, x} -> handler.(x)
    end
  end

  def throwIO(_e) do
  end
end
