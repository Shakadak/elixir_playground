defmodule TVar do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro tv(x), do: quote(do: %unquote(__MODULE__){@: unquote(x)})
end

defmodule Type do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro tvar(x), do: quote(do: %unquote(__MODULE__){@: {:tvar, unquote(x)}})
  defmacro tcon(x), do: quote(do: %unquote(__MODULE__){@: {:tcon, unquote(x)}})
  defmacro tarr(t1, t2), do: quote(do: %unquote(__MODULE__){@: {:tarr, {unquote(t1), unquote(t2)}}})

  def typeInt, do: tcon("Int")
  def typeBool, do: tcon("Bool")

end

defmodule Scheme do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro forall(tvars, type), do: quote(do: %unquote(__MODULE__){@: {unquote(tvars), unquote(type)}})
end

defmodule Syntax do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro var(x), do: quote(do: %unquote(__MODULE__){@: {:var, unquote(x)}})
  defmacro app(a1, a2), do: quote(do: %unquote(__MODULE__){@: {:app, {unquote(a1), unquote(a2)}}})
  defmacro lam(a1, a2), do: quote(do: %unquote(__MODULE__){@: {:lam, {unquote(a1), unquote(a2)}}})
  defmacro let(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:let, {unquote(a1), unquote(a2), unquote(a3)}}})
  defmacro lit(x), do: quote(do: %unquote(__MODULE__){@: {:lit, unquote(x)}})
  defmacro ifO(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:if, {unquote(a1), unquote(a2), unquote(a3)}}})
  defmacro fix(x), do: quote(do: %unquote(__MODULE__){@: {:fix, unquote(x)}})
  defmacro op(a1, a2, a3), do: quote(do: %unquote(__MODULE__){@: {:op, {unquote(a1), unquote(a2), unquote(a3)}}})
end

defmodule TypeEnv do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro typeEnv(x), do: quote(do: %unquote(__MODULE__){@: unquote(x)})

  def extend(typeEnv(env), {x, s}), do: typeEnv(Map.put(env, x, s))

  def empty, do: typeEnv(Map.new())
end

defmodule Sd.Infer do
  @enforce_keys [:runState]
  defstruct [:runState]
  
  defmacro state(x), do: quote(do: %unquote(__MODULE__){runState: unquote(x)})

  alias Data.Result
  require Result

  alias ComputationExpression, as: CE
  require CE

  require TVar
  require Scheme
  require Type
  require TypeEnv
  require Syntax

  # s -> {s, result(e, a)}
  def pure(x), do: state(fn s -> {s, Result.pure(x)} end)

  def runInfer(m) do
    case evalState(m, 0) do
      Result.ok(res) -> closeOver(res)
      Result.error(err) -> Result.error(err)
    end
  end

  # closeOver :: (Map.Map TVar Type, Type) -> Scheme
  def closeOver({sub, ty}) do
    sc = generalize(Substitutable.apply(ty, sub), TypeEnv.empty())
    normalize(sc)
  end

  def letters do
    Stream.iterate(1, & &1 + 1) |> Stream.flat_map(fn n -> Stream.map(?a..?z, &to_string(List.duplicate(&1, n))) end)
  end

  # normalize :: Scheme -> Scheme
  def normalize(Scheme.forall(_ts, body)) do
    ord = Enum.zip(Enum.uniq(fv(body)), Stream.map(letters(), &TVar.tv/1))
    snd = fn {_, y} -> y end
    Scheme.forall(Enum.map(ord, snd), normtype(body, ord))
  end

  def fv(Type.tvar(a)), do: [a]
  def fv(a |> Type.tarr(b)), do: fv(a) ++ fv(b)
  def fv(Type.tcon(_)), do: []

  def normtype(Type.tarr(a, b), ord), do: Type.tarr(normtype(a, ord), normtype(b, ord))
  def normtype(Type.tcon(a), _), do: Type.tcon(a)
  def normtype(Type.tvar(a), ord) do
    case Map.fetch(ord, a) do
      {:ok, x} -> Type.tvar(x)
      :error -> raise("type variable not in signature")
    end
  end

  def fresh do
    CE.compute __MODULE__ do
      let! s = get()
      put %{s | count: s.count + 1}
      pure Type.tvar(Enum.at(letters(), s.count))
    end
  end

  # occursCheck ::  Substitutable a => TVar -> a -> Bool
  def occursCheck(a, t), do: Substitutable.ftv(t) |> MapSet.member?(a)

  # unify ::  Type -> Type -> Infer Subst
  def unify(l1 |> Type.tarr(r1), l2 |> Type.tarr(r2)) do
    CE.compute __MODULE__ do
      let! s1 = unify(l1, l2)
      let! s2 = unify(Substitutable.apply(r1, s1), Substitutable.apply(r2, s1))
      pure s2 |> Subst.compose(s1)
    end
  end

  def unify(Type.tvar(a), t), do: bindTo(a, t)
  def unify(t, Type.tvar(a)), do: bindTo(a, t)
  def unify(Type.tcon(a), Type.tcon(b)) when a == b, do: pure Subst.nullSubst()
  def unify(t1, t2), do: throwError({:unification_fail, {t1, t2}})


  # bindTo ::  TVar -> Type -> Infer Subst
  def bindTo(a, t) do
    cond do
      t == Type.tvar(a) -> pure Subst.nullSubst()
      occursCheck(a, t) -> throwError({:infinite_type, {a, t}})
      :otherwise -> pure %{a => t}
    end
  end

  # instantiate ::  Scheme -> Infer Type
  def instantiate(Scheme.forall(as, t)) do
    CE.compute __MODULE__ do
      let! as2 = mapM(as, fn _ -> fresh() end)
      s = Map.new(Enum.zip(as, as2))
      pure Substitutable.apply(t, s)
    end
  end

  # generalize :: TypeEnv -> Type -> Scheme
  def generalize(env, t) do
    as = MapSet.to_list(MapSet.difference(Substitutable.ftv(t), Substitutable.ftv(env)))
    Scheme.forall(as, t)
  end

  # lookupEnv :: TypeEnv -> Var -> Infer (Subst, Type)
  def lookupEnv(TypeEnv.typeEnv(env), x) do
    case Map.fetch(env, x) do
      :error -> throwError({:unbound_variable, inspect(x)})
      {:ok, s} ->
        CE.compute __MODULE__ do
          let! t = instantiate(s) 
          pure {Subst.nullSubst(), t}
        end
    end
  end

  def infer(env, ex) do
    case ex do
      Syntax.var(x) -> lookupEnv(env, x)

      Syntax.lam(x, e) ->
        CE.compute __MODULE__ do
          let! tv = fresh()
          env2 = env |> TypeEnv.extend({x, Scheme.forall([], tv)})
          let! {s1, t1} = infer(env2, e)
          pure {s1, Substitutable.apply(tv, s1) |> Type.tarr(t1)}
        end

      Syntax.app(e1, e2) ->
        CE.compute __MODULE__ do
          let! tv = fresh()
          let! {s1, t1} = infer(env, e1)
          let! {s2, t2} = infer(Substitutable.apply(env, s1), e2)
          let! s3       = unify(Substitutable.apply(t1, s2), Type.tarr(t2, tv))
          pure {s3 |> Subst.compose(s2) |> Subst.compose(s1), Substitutable.apply(tv, s3)}
        end
    end
  end

  def evalState(m, s) do
    {_s, x} = m.runState.(s)
    x
  end

  def throwError(x), do: state(fn s -> {s, Result.error(x)} end)

  # State s (Result e s)
  def get do
    state(fn s -> {s, Result.pure(s)} end)
  end

  # s -> State s (Result e ())
  def put(s) do
    state(fn _ -> {s, Result.pure({})} end)
  end

  # (s -> s) -> State s (Result e ())
  def modify(f) do
    state(fn s -> {f.(s), Result.pure({})} end)
  end

  # State s (Result e a) -> (a -> State s (Result e b)) -> State s (Result e b)
  def bind(mra, f) do
    state(fn s ->
      {s, ra} = mra.runState.(s)
      case ra do
        Result.ok(a) -> f.(a).runState.(s)
        Result.error(_) -> {s, ra}
      end
    end)
  end

  def mapM([], _), do: pure([])
  def mapM([x | xs], f) do
    CE.compute __MODULE__ do
      let! y = f.(x)
      let! ys = mapM(xs, f)
      pure([y | ys])
    end
  end
end

defmodule Subst do
  @enforce_keys [:@]
  defstruct [:@]

  defmacro subst(x), do: quote(do: %unquote(__MODULE__){@: unquote(x)})

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

defimpl Substitutable, for: List do
  def apply(xs, s), do: Enum.map(xs, &Substitutable.apply(&1, s))

  def ftv(xs), do: Enum.reduce(xs, MapSet.new(), &MapSet.union(Substitutable.ftv(&1), &1))
end

defimpl Substitutable, for: TypeEnv do
  import TypeEnv

  def apply(typeEnv(env), s), do: typeEnv(Map.new(env, fn {k, v} -> {k, Substitutable.apply(v, s)} end))

  def ftv(typeEnv(env)), do: Map.values(env)
end
