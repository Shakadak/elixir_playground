defmodule Ast do
  alias ComputationExpression, as: CE
  require CE

  alias Wrapped.ResultState
  alias Base.Result
  require Result

  alias   DataTypes, as: DT
  require DT

  import  Ast.Core, only: [
    app: 2,
    clause: 2,
    gclause: 3,
    lam: 2,
    # let: 2,
    lit: 1,
    # non_rec: 2,
    var: 1,
  ]

  import  Ast.Core.Typed, only: [
    app_t: 3,
    case_t: 3,
    clause_t: 4,
    lam_t: 3,
    let_t: 3,
    lit_t: 2,
    non_rec_t: 3,
    var_t: 2,
  ]

  defmacro mismatched_types(found, expected) do
    {:mismatched_types, {found, expected}}
  end

  defmacro unknown_type do
    :unknown_type
  end

  def is_output_concrete?(type) do
    IO.inspect(type, label: "is_output_concrete?")
    case type do
      DT.variable(_name) ->
        false

      DT.type(_) ->
        true

      _ ->
        false
    end
  end

  def is_fun_output_concrete?() do
  end

  def empty_state, do: %{vars: %{}, seed: 0}

  def tvar_from_num(n) do
    [Enum.at(?a..?z, rem(n, 26)) | ~c"#{div(n, 26)}"]
    |> List.to_atom()
  end

  def gen_var do
    ResultState.state(&get_and_update_in(&1, [Ast.Access.seed()], fn seed -> {tvar_from_num(seed), seed + 1} end))
  end

  def put_var_type(var, type) do
    ResultState.modify &put_in(&1, [Ast.Access.vars(), var], type)
  end

  def infer(ast) do
    import Result
    # We might not even need the Result workflow, only State
    CE.compute Workflow.ResultState do
      match ast do
        lit(x) when is_integer(x) ->
          pure DT.type(:integer)

        lit(x) when is_atom(x) ->
          pure DT.type(:atom)

        # If its a variable, we check if we have it in the env
        # If not, we synthesize a variable that needs to be filled later
        # Erroring now is a mistake
        var(v) ->
          let! vars = ResultState.gets(&get_in(&1, [Ast.Access.vars()]))
          Data.Map.fetch(vars, v)
          |> match do
            ok found -> pure found
            error _ ->
              let! new_var = gen_var()
              let type = DT.variable(new_var)
              do! ResultState.modify &put_in(&1, [Ast.Access.vars(), v], type)
              pure type
          end

        lam(args, expr) ->
          let! args_t = ResultState.mapM(args, &infer/1)
          let! expr_t = infer(expr)
          pure DT.fun(args_t, expr_t)
      end
    end
  end

  def check(ast, expected_type) do
    CE.compute Workflow.ResultState do
      match ast do
        lit(_) = ast ->
          let! found = infer(ast)
          match found do
            ^expected_type -> pure {}
            other_type -> pure! ResultState.throwError mismatched_types other_type, expected_type
          end

        var(_) = ast ->
          match! infer(ast) do
            ^expected_type -> pure {}
            other_type -> pure! ResultState.throwError mismatched_types other_type, expected_type
          end

        app(e, args) ->
          # For this application
          # we want to override the type of e
          # but not after
          match! infer(e) do
            DT.fun(params_types, output_type) ->
              let c = CE.compute Workflow.ResultState do
                #let _ = IO.inspect([infered: output_type, expected: expected_type], label: "pre unify")
                do! unify(output_type, expected_type)
                #let _ = IO.inspect([out: output_type, ins: params_types], label: "pre propagate")
                pure! ResultState.mapM(params_types, &propagate/1)
              end
              let! params_type = local(c, %{tvars: %{}})
              pure! ResultState.zipWithM_(args, params_type, &check(&1, &2))


            other_type ->
              pure! ResultState.throwError mismatched_types other_type, expected_type
          end

        lam(inputs, expr) ->
          match expected_type do
            DT.fun(inputs_types, out_type) ->
              do! ResultState.zipWithM_(inputs, inputs_types, &Ast.Check.pattern/2)
              pure! check(expr, out_type)

            _other ->
              pure! ResultState.throwError mismatched_types DT.fun(List.duplicate(DT.unknown(), length(inputs)), DT.unknown()), expected_type
          end

        Ast.Core.case(inputs, clauses) ->
          let! inputs_types = ResultState.mapM(inputs, &infer/1)
          pure! ResultState.mapM_(clauses, fn clause(pats, expr) ->
            CE.compute Workflow.ResultState do
              do! ResultState.zipWithM_(pats, inputs_types, &Ast.Check.pattern/2)
              pure! check(expr, expected_type)
            end
          end)
      end
    end
  end

  def unify(infered, expected) do
    CE.compute Workflow.ResultState do
      match {infered, expected} do
        {eq, eq} -> pure {}
        {DT.rigid_variable(name), DT.type(_) = t} ->
          do! ResultState.modify fn s -> put_in(s, [:tvars, name], t) end
        {DT.rigid_variable(name), DT.fun(_, _) = t} ->
          do! ResultState.modify fn s -> put_in(s, [:tvars, name], t) end
        _ -> do! raise "unimplemented"
      end
    end
  end

  def propagate(type) do
    import Result
    CE.compute Workflow.ResultState do
      match type do
        DT.type(t) -> pure DT.type(t)
        DT.rigid_variable(name) = t ->
          let! vars = ResultState.gets(&get_in(&1, [:tvars]))
          Data.Map.fetch(vars, name)
          |> match do
            ok(t) -> pure t
            error(_err) -> pure t
            #error(err) -> pure! ResultState.throwError err
          end

        DT.fun(ins, out) ->
          let! ins = ResultState.mapM(ins, &propagate/1)
          let! out = propagate(out)
          pure DT.fun(ins, out)

        _ -> do! raise "unimplemented"
      end
    end
  end

  def local(m, state) do
    require Transformer.StateT
    fn s ->
      m.(state)
      |> Base.Result.bind(fn {a, _s2} -> Base.Result.pure({a, s}) end)
    end
    #CE.compute Workflow.ResultState, debug: true do
    #  let! s = ResultState.get()
    #  do! ResultState.put(state)
    #  let! x = m
    #  do! ResultState.put(s)
    #  pure x
    #end
  end

  #def locally(m, open, close) do
  #  Transformer.StateT.mkStateT fn s ->
  #    Transformer.StateT.runStateT(m, s)
  #    |> Base.Result.bind(fn {a, s2} ->
  #      Transformer.StateT.runStateT(m.(a), s2)
  #    end)
  #  end
  #  #CE.compute Workflow.ResultState do
  #  #  do! ResultState.withStateT(open)
  #  #  let! x = k
  #  #  do! ResultState.withStateT(close)
  #  #  pure x
  #  #end
  #end

  @spec annotate(ast, :check | :synthesize, env) :: Result.t(any, any)
    when ast: any, env: any
  def annotate(ast, mode, env)

  def annotate(ast, :check = mode, env) do
    case ast do
      var(id) ->
        case Map.fetch(env, id) do
          {:ok, type} -> Result.ok(var_t(id, type))
          :error -> Result.error({:not_in_scope, id})
        end

      app(e, args) ->
        CE.compute Workflow.Result do
          let! e_t = annotate(e, mode, env)
          let! args_t = Result.mapM(args, &annotate(&1, mode, env))
          pure app_t(e_t, args_t, DT.unknown())
        end

      Ast.Core.case(exprs, clauses) ->
        CE.compute Workflow.Result do
          let! exprs_t = Result.mapM(exprs, &annotate(&1, mode, env))
          let! clauses_t = Result.mapM(clauses, &annotate(&1, mode, env))
          pure Ast.Core.Typed.case_t(exprs_t, clauses_t, DT.unknown())
        end

      gclause(pats, guards, expr) ->
        CE.compute Workflow.Result do
          let! pats_t = Result.mapM(pats, &annotate(&1, mode, env))
          let! guards_t = Result.mapM(guards, &annotate(&1, mode, env))
          let! expr_t = annotate(expr, mode, env)
          pure clause_t(pats_t, guards_t, expr_t, DT.unknown())
        end
    end
  end

  def annotate(ast, :synthesize = _mode, _env) do
    case ast do
      lit(x) when is_integer(x) -> Result.ok(lit_t(x, DT.type(:integer)))
      lit(x) when is_atom(x) -> Result.ok(lit_t(x, DT.type(:atom)))
    end
  end

  def jjjj(ast) do
    case ast do
      var_t(_, t) -> t
      lit_t(_, t) -> t
      app_t(_, _, t) -> t
      lam_t(_, _, t) -> t
      let_t(_, _, t) -> t
      non_rec_t(_, _, t) -> t
      case_t(_, _, t) -> t
      clause_t(_, _, _, t) -> t
    end
    |> case do
      :_? -> Result.error(:no_type)
      other -> Result.ok(other)
    end
  end
end
