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

  def initInfer, do: %{count: 0}

  @doc """
  Run the inference monad.
  """
  def runInfer(env, m) do
    Data.ResultRWS.evalRwsT(m, env, initInfer())
  end

  @doc """
  Solve for the top level type of an expression in a given environment.
  """
  def inferExpr(env, ex) do
    CE.compute Data.Result do
      let! {ty, cs} = runInfer(env, infer(ex))
      let! subst = runSolve(cs)
      pure closeOver(Substitutable.apply(ty, subst))
    end
  end

  @doc """
  Return the internal constraints used in solving the type of an expression.
  """
  def constraintsExpr(env, ex) do
    CE.compute Data.Result do
      let! {ty, cs} = runInfer(env, infer(ex))
      let! subst = runSolve(cs)
      sc = closeOver(Substitutable.apply(ty, subst))
      pure {cs, subst, ty, sc}
    end
  end

  # closeOver :: Type -> Scheme
  def closeOver(ty) do
    normalize(generalize(TypeEnv.empty(), ty))
  end

  def uni(t1, t2), do: Data.ResultRWS.tell([{t1, t2}])

  def inEnv({x, sc}, m) do
    CE.compute Data.ResultRWS do
      scope = fn e -> TypeEnv.remove(e, x) |> TypeEnv.extend({x, sc}) end
      Data.ResultRWS.local(scope, m)
    end
  end

  # lookupEnv :: Name -> Infer Type
  def lookupEnv(x) do
    CE.compute Data.ResultRWS do
      let! TypeEnv.typeEnv(env) = Data.ResultRWS.ask()
      case Map.fetch(env, x) do
        :error -> Data.ResultRWS.throwError({:unbound_variable, inspect(x)})
        {:ok, s} -> instantiate(s) 
      end
    end
  end

  def letters do
    Stream.iterate(1, & &1 + 1) |> Stream.flat_map(fn n -> Stream.map(?a..?z, &to_string(List.duplicate(&1, n))) end)
  end

  def fresh do
    CE.compute Data.ResultRWS do
      let! s = Data.ResultRWS.get()
      Data.ResultRWS.put(%{s | count: s.count + 1})
      pure Type.tvar(TVar.tv(Enum.at(letters(), s.count)))
    end
  end

  # instantiate ::  Scheme -> Infer Type
  def instantiate(Scheme.forall(as, t)) do
    CE.compute Data.ResultRWS do
      let! as2 = Data.ResultRWS.mapM(as, fn _ -> fresh() end)
      s = Map.new(Enum.zip(as, as2))
      pure Substitutable.apply(t, s)
    end
  end

  # generalize :: TypeEnv -> Type -> Scheme
  def generalize(env, t) do
    as = MapSet.to_list(MapSet.difference(Substitutable.ftv(t), Substitutable.ftv(env)))
    Scheme.forall(as, t)
  end

  # normalize :: Scheme -> Scheme
  def normalize(Scheme.forall(_ts, body)) do
    ord = Enum.zip(Enum.uniq(fv([], body)), Stream.map(letters(), &TVar.tv/1))
    snd = fn {_, y} -> y end
    Scheme.forall(Enum.map(ord, snd), normtype(body, ord))
  end

  def fv(xs, Type.tvar(a)), do: xs ++ [a]
  def fv(xs, Type.tarr(a, b)), do: fv(xs, a) ++ fv(xs, b)
  def fv(_, Type.tcon(_)), do: []

  def normtype(Type.tarr(a, b), ord), do: Type.tarr(normtype(a, ord), normtype(b, ord))
  def normtype(Type.tcon(a), _), do: Type.tcon(a)
  def normtype(Type.tvar(a), ord) do
    case Map.fetch(ord, a) do
      {:ok, x} -> Type.tvar(x)
      :error -> raise("type variable not in signature")
    end
  end

  # ops :: Map.Map Binop Type
  def ops, do: %{
    "+"  => Type.typeInt |> Type.tarr(Type.typeInt |> Type.tarr(Type.typeInt)),
    "*"  => Type.typeInt |> Type.tarr(Type.typeInt |> Type.tarr(Type.typeInt)),
    "-"  => Type.typeInt |> Type.tarr(Type.typeInt |> Type.tarr(Type.typeInt)),
    "==" => Type.typeInt |> Type.tarr(Type.typeInt |> Type.tarr(Type.typeBool)),
  }

  # infer :: Expr -> Infer Type
  def infer(ex) do
    case ex do
      Syntax.lit(Syntax.lint(_)) -> Data.ResultRWS.pure(Type.typeInt())
      Syntax.lit(Syntax.lbool(_)) -> Data.ResultRWS.pure(Type.typeBool())

      Syntax.var(x) -> lookupEnv(x)

      Syntax.lam(x, e) ->
        CE.compute Data.ResultRWS do
          let! tv = fresh()
          let! t = inEnv({x, Scheme.forall([], tv)}, infer(e))
          pure Type.tarr(tv, t)
        end

      Syntax.app(e1, e2) ->
        CE.compute Data.ResultRWS do
          let! t1 = infer(e1)
          let! t2 = infer(e2)
          let! tv = fresh()
          uni(t1, Type.tarr(t2, tv))
          pure tv
        end

      Syntax.op(op, e1, e2) ->
        CE.compute Data.ResultRWS do
          let! t1 = infer(e1)
          let! t2 = infer(e2)
          let! tv = fresh()
          u1 = t1 |> Type.tarr(t2 |> Type.tarr(tv))
          u2 = Map.fetch!(ops(), op)
          uni(u1, u2)
          pure tv
        end
    end
  end

  def inferTop(env, []), do: Data.Result.ok(env)
  def inferTop(env, [{name, ex} | xs]) do
    CE.compute Data.Result do
      let! ty = inferExpr(env, ex)
      inferTop(TypeEnv.extend(env, {name, ty}), xs)
    end
  end

  ###
  # Constraint Solver
  ###

  @doc """
  Run the constraint solver

  ```
  runSolve :: [Constraint] -> Either TypeError Subst
  ```
  """
  def runSolve(cs) do
    st = {Subst.nullSubst(), cs}
    Data.ResultState.evalStateT(solver(), st)
  end

  def emptyUnifier, do: {Subst.nullSubst(), []}

  def unifyMany([], []), do: Data.ResultState.pure emptyUnifier()
  def unifyMany([t1 | ts1], [t2 | ts2]) do
    CE.compute Data.ResultState do
      let! {su1, cs1} = unifies(t1, t2)
      let! {su2, cs2} = unifyMany(Substitutable.apply(ts1, su1), Substitutable.apply(ts2, su1))
      pure {Subst.compose(su2, su1), cs1 ++ cs2}
    end
  end
  def unifyMany(t1, t2), do: Data.ResultState.throwError({:unification_mismatch, {t1, t2}})

  def unifies(t, t), do: Data.ResultState.pure emptyUnifier()
  def unifies(Type.tvar(v), t), do: bindTo(v, t)
  def unifies(t, Type.tvar(v)), do: bindTo(v, t)
  def unifies(Type.tarr(t1, t2), Type.tarr(t3, t4)), do: unifyMany([t1, t2], [t3, t4])
  def unifies(t1, t2), do: Data.ResultState.throwError({:unification_fail, {t1, t2}})

  # unification solver
  def solver do
    CE.compute Data.ResultState do
      let! {su, cs} = Data.ResultState.get()
      case cs do
        [] -> Data.ResultState.pure su
        [{t1, t2} | cs0] ->
          CE.compute Data.ResultState do
            let! {su1, cs1} = unifies(t1, t2)
            Data.ResultState.put({Subst.compose(su1, su), cs1 ++ Substitutable.apply(cs0, su1)})
            solver()
          end
      end
    end
  end

  # bindTo ::  TVar -> Type -> Infer Subst
  def bindTo(a, t) do
    cond do
      t == Type.tvar(a) -> Data.ResultState.pure {Subst.nullSubst(), []}
      occursCheck(a, t) -> Data.ResultState.throwError({:infinite_type, {a, t}})
      :otherwise -> Data.ResultState.pure {%{a => t}, []}
    end
  end

  # occursCheck ::  Substitutable a => TVar -> a -> Bool
  def occursCheck(a, t), do: Substitutable.ftv(t) |> MapSet.member?(a)
end
