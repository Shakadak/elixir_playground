defmodule Nbe do
  import PatternMetonyms, only: [
    view: 2,
  ]

  require Struct


  Struct.mk clos(env: environment, var: symbol, body: any)
  Struct.mk zero
  Struct.mk add1(pred: value)
  Struct.mk n_ap(rator: neutral, rand: value)
  Struct.mk n_rec(type: type, target: neutral, base: norm, step: norm)
  Struct.mk n_var(name: symbol)
  Struct.mk go(result: any)
  Struct.mk stop(expr: expression, message: String.t)
  Struct.mk the(type: type, value: value)
  Struct.mk def!(type: type, value: value)
  Struct.mk neu(type: value, neu: neutral)

  @type environment :: Keyword.t
  @type symbol :: atom
  @type value :: any
  @type expression :: any
  @type void :: {}
  @type neutral :: any
  @type context :: any
  @type perhaps(_a) :: go | stop
  @type type :: any
  @type norm :: any
  @type definitions :: [def!]

  @spec assv(any, list(tuple)) :: tuple | false
  def assv(k, lst) do
    Keyword.fetch(lst, k)
    |> case do
      {:ok, v} -> {k, v}
      :error -> false
    end
  end

  @doc """
  Returns the second element of the pair `p`.
  """
  @spec cdr({any, a}) :: a when a: any
  def cdr({_, y}), do: y

  @doc """
  Returns the first element of the pair `p`.
  """
  @spec car({a, any}) :: a when a: var
  def car({x, _}), do: x

  def cons(a, d) when is_list(d), do: [a | d]
  def cons(a, d), do: {a, d}

  @spec displayln(any) :: void
  def displayln(v), do: (IO.inspect(v); {})

  @spec memv(any, list | any) :: false | list
  def memv(x, [x | _] = lst), do: lst
  def memv(_, []), do: false
  def memv(x, [_ | rest]), do: memv(x, rest)

  @spec (map fun, list) :: list
  def (map f, xs), do: (Enum.map xs, f)

  @spec symbol?(any) :: boolean
  def symbol?(x), do: is_atom(x)

  @spec extend(environment, symbol, value) :: environment
  def extend(p, x, v), do:
    cons({x, v}, p)

  @spec val(environment, expression) :: value
  def val(p, e) do
    view e do
      [f, [x], b] when f in [:lam, :λ] ->
        clos(p, x, b)

      x when (symbol? x) ->
        xv = assv(x, p)
        if xv do
          cdr(xv)
        else
          raise "Unknown variable #{inspect(x)}"
        end

      [rator, rand] ->
        do_ap(val(p, rator), val(p, rand))
    end
  end

  @spec do_ap(value, value) :: value
  def do_ap(fun, arg) do
    case fun do
      clos(p, x, b) ->
        val(extend(p, x, arg), b)

      _neutral_fun ->
        n_ap(fun, arg)
    end
  end

  @spec run_program(environment, list(expression)) :: void
  def run_program(p, exprs) do
    case exprs do
      [] -> {}
      [[:define, x, e] | rest] ->
        v = val(p, e)
        run_program(extend(p, x, v), rest)

      [e | rest] ->
        {} = displayln(norm(p, e))
        run_program(p, rest)
    end
  end

  @spec add_star(symbol) :: symbol
  def add_star(x), do: :"#{x}*"

  @spec freshen(list(symbol), symbol) :: symbol
  def freshen(used, x) do
    if memv(x, used) do
      freshen(used, add_star(x))
    else
      x
    end
  end

  @spec read_back(list(symbol), value) :: expression
  def read_back(used_names, v) do
    case v do
      clos(p, x, body) ->
        y = freshen(used_names, x)
        neutral_y = n_var(y)
        [:λ, [y], read_back(cons(y, used_names), val(extend(p, x, neutral_y), body))]

      n_var(x) ->
        x

      n_ap(rator, rand) ->
        [read_back(used_names, rator), read_back(used_names, rand)]
    end
  end

  @spec norm(environment, expression) :: expression
  def norm(p, e) do
    read_back([], val(p, e))
  end

  @spec with_numerals(expression) :: expression
  def with_numerals(e) do
    [
      [:define, :church_zero,
        [:λ, [:f], [:λ, [:x], :x]]],
      [:define, :church_add1,
        [:λ, [:n_1],
          [:λ, [:f],
            [:λ, [:x],
              [:f, [[:n_1, :f], :x]]]]]],
      e
    ]
  end

  def positive?(n), do: n > 0

  @spec to_church(non_neg_integer) :: expression
  def to_church(n) do
    cond do
      n == 0 ->
        :church_zero

      positive?(n) ->
        church_of_n_minus_1 = to_church(n - 1)
        [:church_add1, church_of_n_minus_1]
    end
  end

  @spec church_add :: expression
  def church_add do
    [:λ, [:j],
      [:λ, [:k],
        [:λ, [:f],
          [:λ, [:x],
            [[:j, :f], [[:k, :f], :x]]]]]]
  end

  # 4 Error Handling

  defmacro go_on(chain, result) do
    go_on_go(chain, result)
  end

  def go_on_go([], result) do
    result
  end

  def go_on_go([[pat0, e0] | rest], result) do
    quote generated: true do
      case unquote(e0) do
        go(unquote(pat0)) -> go_on(unquote(rest), unquote(result))
        go(v) -> raise "go_on: Pattern did not match value #{inspect(v)}"
        stop(expr, msg) -> stop(expr, msg)
      end
    end
  end

  # 5 Bidirectional Type Checking

  # 5.1 Types

  @spec type_eq?(any, any) :: boolean
  def type_eq?(t1, t2) do
    case {t1, t2} do
      {:Nat, :Nat} -> true
      {[:->, a1, b1], [:->, a2, b2]} ->
        type_eq?(a1, a2) and type_eq?(b1, b2)
      {_, _} -> false
    end
  end

  @spec type?(any) :: boolean
  def type?(t), do: type_eq?(t, t)

  # 5.2 Checking Types

  @spec synth(context, expression) :: perhaps(type)
  def synth(context, expression) do
    case expression do
      # Type annotations
      [:the, t, e2] ->
        if not type?(t) do
          stop(expression,  "Invalid type #{inspect(t)}")
        else
          go_on([[_, check(context, e2, t)]],
            go(t))
        end

      # Recursion on Nat
      [:rec, type, target, base, step] ->
        go_on([
          [target_t, synth(context, target)],
          [_, if type_eq?(target_t, :Nat) do
            go(:ok)
          else
            stop(target, "Expected Nat, got #{inspect(target_t)}")
          end],
          [_, (check context, base, type)],
          [_, (check context, step, [:->, :Nat, [:->, type, type]])],
        ],
          go(type)
        )

      x when is_atom(x) and x not in [:the, :rec, :λ, :zero, :add1] ->
        case assv(x, context) do
          false -> (stop x, "Variable not found")
          {_, t} -> (go t)
        end

      [rator, rand] ->
        go_on([[rator_t, (synth context, rator)]],
          case rator_t do
            [:->, a, b] ->
              go_on([[_, (check context, rand, a)]],
                (go b))

            _ ->
              (stop rator, "Not a function type: #{inspect(rator_t)}")
          end
        )
    end
  end

  @spec check(context, expression, type) :: perhaps(:ok)
  def check(gamma, e, t) do
    case e do
      :zero ->
        if (type_eq? t, :Nat) do
          (go :ok)
        else
          (stop e, "Tried to use #{inspect(t)} for zero")
        end

      [:add1, n] ->
        if (type_eq? t, :Nat) do
          (go_on [[_, (check gamma, n, :Nat)]],
            (go :ok))
        else
          (stop e, "Tried to use #{inspect(t)} for add1")
        end

      [:λ, [x], b] ->
        case t do
          [:->, tA, tB] ->
            (go_on [[_, (check (extend gamma, x, tA), b, tB)]],
              (go :ok))

          non_arrow ->
            (stop e, "Instead of :-> type, got #{inspect(non_arrow)}")
        end

      _other ->
        (go_on [[t2, (synth gamma, e)]],
          (if (type_eq? t, t2) do
            (go :ok)
          else
            (stop e, "Synthesized type #{inspect(t2)} where type #{inspect(t)} was expected")
          end))
    end
  end

  # 5.3 Definitions

  @type define :: any # [:define, atom, expression]
  @spec check_program(context, prog) :: perhaps(context)
    when prog: [expression | define]
  def check_program(gamma, prog) do
    case prog do
      [] ->
        (go gamma)

      [[:define, x, e] | rest] ->
        (go_on [[t, (synth gamma, e)]],
          (check_program (extend gamma, x, t), rest))

      [e | rest] ->
        (go_on [[t, (synth gamma, e)]],
          ((IO.puts "#{inspect(e)} has type #{inspect(t)}")
            (check_program gamma, rest)))
    end
  end

  # 6 Typed Normalization by Evaluation

  # 6.1 Values for Typed NbE

  # 6.2 The Evaluator

  @spec tval(environment, expression) :: value
  def tval(rho, e) do
    case e do
      [:the, _type, expr] ->
        (tval rho, expr)

      :zero -> zero()

      [:add1, n] -> (add1 (tval rho, n))


      x when is_atom(x) and x not in [:the, :zero, :add1, :λ, :rec] ->
        xv = assv(x, rho)
        if xv do
          (cdr xv)
        else
          raise "Unknown variable #{inspect(x)}"
        end

      [:λ, [x], b] ->
        (clos rho, x, b)

      [:rec, type, target, base, step] ->
        (tdo_rec type, (tval rho, target), (tval rho, base), (tval rho, step))

      [rator, rand] ->
        (tdo_ap (tval rho, rator), (tval rho, rand))
    end
  end

  @spec tdo_ap(value, value) :: value
  def tdo_ap(fun, arg) do
    case fun do
      (clos rho, x, e) ->
        (tval (extend rho, x, arg), e)

      (neu [:->, tA, tB], ne) ->
        (neu tB, (n_ap ne, (the tA, arg)))
    end
  end

  @spec tdo_rec(type :: type, target :: value, base :: value, step :: value) :: value
  def tdo_rec(type, target, base, step) do
    case target do
      zero() -> base
      (add1 n) ->
        (tdo_ap (tdo_ap step, n),
               (tdo_rec type, n, base, step))

      (neu :Nat, ne) ->
        (neu type,
          (n_rec type,
                 ne,
                 (the type, base),
                 (the [:->, :Nat, [:->, type, type]], step)))
    end
  end

  # 6.3 Typed Read-Back

  @spec tread_back(list(symbol), type, value) :: expression
  def tread_back(used_names, type, value) do
    case type do
      :Nat ->
        case value do
          zero() -> :zero
          (add1 n) -> [:add1, (tread_back used_names, :Nat, n)]
          (neu _, ne) ->
            (tread_back_neutral used_names, ne)
        end

      [:->, tA, tB] ->
        x = (freshen used_names, :x)
        [:λ, [x], (tread_back (cons x, used_names),
          tB,
          (tdo_ap value, (neu tA, (n_var x))))]
    end
  end

  @spec tread_back_neutral(list(symbol), neutral) :: expression
  def tread_back_neutral(used_names, ne) do
    case ne do
      (n_var x) -> x

      (n_ap fun, (the arg_type, arg)) ->
        [(tread_back_neutral used_names, fun), (tread_back used_names, arg_type, arg)]

      (n_rec type, target, (the base_type, base), (the step_type, step)) ->
        [:rec, type,
          (tread_back_neutral used_names, target),
          (tread_back used_names, base_type, base),
          (tread_back used_names, step_type, step),]
    end
  end

  # 6.4 Programs With Definitions

  @spec defs2ctx(definitions) :: context
  @spec defs2env(definitions) :: environment

  def defs2ctx(big_delta) do
    Enum.map(big_delta, fn {x, (def! type, _)} -> {x, type} end)
  end

  def defs2env(big_delta) do
    Enum.map(big_delta, fn {x, (def! _, value)} -> {x, value} end)
  end

  @spec trun_program(definitions, [define | expression]) :: perhaps(definitions)
  def trun_program(big_delta, prog) do
    case prog do
      [] -> (go big_delta)

      [[:define, x, e] | rest] ->
        (go_on [[type, (synth (defs2ctx big_delta), e)]],
          (trun_program (extend big_delta, x, (def! type, (tval (defs2env big_delta), e))),
            rest))

      [e | rest] ->
        gamma = (defs2ctx big_delta)
        rho = (defs2env big_delta)
        (go_on [[type, (synth gamma, e)]], (
          v = (tval rho, e)
          IO.puts("[:the, #{inspect(type)},\n  #{inspect((tread_back Enum.map(gamma, &car/1), type, v))}]")
          (trun_program big_delta, rest)))
    end
  end

  # 7 A Tiny Piece of Pie

  # 7.1 The Language

  # 7.1.1 Identifiers

  @spec keywords :: [symbol]
  def keywords do
    [
      :define,
      :U,
      :Nat, :zero, :add1, :ind_Nat,
      :Σ, :Sigma, :cons, :car, :cdr,
      :Π, :Pi, :λ, :lambda,
      :=, :same, :replace,
      :Trivial, :sole,
      :Absurd, :ind_Absurd,
      :Atom, :quote,
      :the,
    ]
  end

  @spec keyword?(any) :: boolean
  def keyword?(x) do
    x in keywords()
  end

  @spec var?(any) :: boolean
  def var?(x) do
    symbol?(x) and not keyword?(x)
  end

  # 7.1.2 Program α-equivalence

  @spec α_equiv?(expression, expression) :: boolean
  def α_equiv?(e1, e2) do
    (α_equiv_aux e1, e2, [], [])
  end

  def eqv?(x, y), do: x === y

  def gensym(base \\ "g") do
    :"#{base}#{:erlang.unique_integer([:positive])}"
  end

  @spec α_equiv_aux(expression, expression, [{symbol, symbol}], [{symbol, symbol}]) :: boolean
  def α_equiv_aux(e1, e2, xs1, xs2) do
    view {e1, e2} do
      {kw, kw} when (keyword? kw) ->
        true

      {x, y} when (var? x) and (var? y) ->
        case {(assv x, xs1), (assv y, xs2)} do
          {false, false} -> (eqv? x, y)
          {{_, b1}, {_, b2}} -> (eqv? b1, b2)
          {_, _} -> false
        end

      {[:λ, [x], b1], [:λ, [y], b2]} ->
        fresh = gensym()
        bigger1 = (cons {x, fresh}, xs1)
        bigger2 = (cons {y, fresh}, xs2)
        (α_equiv_aux b1, b2, bigger1, bigger2)

      {[:Π, [{x, ta1}], tb1], [:Π, [{y, ta2}], tb2]} ->
        (α_equiv_aux ta1, ta2, xs1, xs2)
        and (
            fresh = gensym()
            bigger1 = (cons {x, fresh}, xs1)
            bigger2 = (cons {y, fresh}, xs2)
            (α_equiv_aux tb1, tb2, bigger1, bigger2)
          )

      {[:Σ, [{x, ta1}], tb1], [:Σ, [{y, ta2}], tb2]} ->
        (α_equiv_aux ta1, ta2, xs1, xs2)
        and (
            fresh = gensym()
            bigger1 = (cons {x, fresh}, xs1)
            bigger2 = (cons {y, fresh}, xs2)
            (α_equiv_aux tb1, tb2, bigger1, bigger2)
          )

      {x, y} when is_atom(x) and is_atom(y) ->
        (eqv? x, y)

      # This, together with read_back_norm, implements the η law for Absurd.
      {[:the, :Absurd, e1], [:the, :Absurd, e2]} ->
        true

      {[op | args1], [op | args2]} when keyword?(op) ->
        ((length args1) == (length args2))
        and (Enum.all?(Stream.zip_with(args1, args2, &(α_equiv_aux &1, &2, xs1, xs2))))

      {[rator1, rand1], [rator2, rand2]} ->
        (α_equiv_aux rator1, rator2, xs1, xs2)
        and (α_equiv_aux rator1, rator2, xs1, xs2)

      {_, _} ->
        false
    end
  end

  # 7.2 Values and Normalization

  # 7.2.1 The Values

  Struct.mk pi(domain: value, range: closure)
  Struct.mk lam(body: closure)
  Struct.mk sigma(car_type: value, cdr_type: closure)
  Struct.mk pair(car: value, cdr: value)
  Struct.mk nat
  Struct.mk eq(type: value, from: value, to: value)
  Struct.mk same
  Struct.mk trivial
  Struct.mk sole
  Struct.mk absurd
  Struct.mk atom!
  Struct.mk quote!(symbol: symbol)
  Struct.mk uni

  Struct.mk h_o_clos(x: symbol, fun: (value -> value))

  @type closure :: clos | h_o_clos
  @spec closure?(any) :: boolean
  def closure?(c), do: (clos? c) or (h_o_clos? c)

  @spec closure_name(closure) :: symbol
  def closure_name(c) do
    case c do
      (clos _, x, _) -> x
      (h_o_clos x, _) -> x
    end
  end

  # 7.2.2 Neutral Expressions

  @type normal :: any
  Struct.mk n_car(pair: neutral)
  Struct.mk n_cdr(pair: neutral)
  Struct.mk n_ind_Nat(target: neutral, motive: normal, base: normal, step: normal)
  Struct.mk n_replace(target: neutral, motive: normal, base: normal)
  Struct.mk n_ind_Absurd(target: neutral, motive: normal)

  # 7.2.3 Normal Forms

  # 7.3 Definitions and Dependent Types

  Struct.mk bind(type: value)

  @spec context?(any) :: boolean
  def context?(big_gamma) do
    case big_gamma do
      [] -> true
      [{x, b} | rest] ->
        (symbol? x) and ((__MODULE__."def!?" b) or (bind? b)) and (context? rest)
    end
  end

  @spec lookup_type(symbol, context) :: perhaps(value)
  def lookup_type(x, big_gamma) do
    case assv(x, big_gamma) do
      false -> (stop x, "Unknown variable")
      {_, (bind type)} -> (go type)
      {_, (def! type, _)} -> (go type)
    end
  end

  @spec ctx2env(context) :: environment
  def ctx2env(big_gamma) do
    Enum.map(big_gamma, fn
      {name, (bind type)} ->
        {name, (neu type, (n_var name))}
      {name, (def! _, value)} ->
        {name, value}
    end)
  end

  @spec extend_ctx(context, symbol, value) :: context
  def extend_ctx(big_gamma, x, t) do
    [{x, (bind t)} | big_gamma]
  end

  # 7.3.1 The Evaluator

  @spec val_of_closure(closure, value) :: value
  def (val_of_closure c, v) do
    case c do
      (clos rho, x, e) -> (val (extend rho, x, v), e)
      (h_o_clos _x, f) -> (f. v)
    end
  end

  @spec val2(environment, expression) :: value
  def (val2 rho, e) do
    view e do
      [:the, _type, expr] ->
        (val rho, expr)
      :U -> uni()
      [:Π, [{x, tA}], tB] ->
        (pi (val rho, tA), (clos rho, x, tB))
      [:λ, [x], b] ->
        (lam (clos rho, x, b))
      [:Σ, [{x, tA}], tD] ->
        (sigma (val rho, tA), (clos rho, x, tD))
      [:cons, a, d] ->
        (pair (val rho, a), (val rho, d))
      [:car, pr] ->
        (do_car (val rho, pr))
      [:cdr, pr] ->
        (do_cdr (val rho, pr))
      :Nat -> nat()
      :zero -> zero()
      [:add1, n] -> (add1 (val rho, n))
      [:ind_Nat, target, motive, base, step] ->
        (do_ind_Nat (val rho, target), (val rho, motive), (val rho, base), (val rho, step))
      [:=, tA, from, to] ->
        (eq (val rho, tA), (val rho, from), (val rho, to))
      :same ->
        same()
      [:replace, target, motive, base] ->
        (do_replace (val rho, target), (val rho, motive), (val rho, base))
      :Trivial -> trivial()
      :sole -> sole()
      :Absurd -> absurd()
      [:ind_Absurd, target, motive] -> (do_ind_Absurd (val rho, target), (val rho, motive))
      :Atom -> atom!()
      a when is_atom(a) -> (quote! a)
      [rator, rand] ->
        (do_ap (val rho, rator), (val rho, rand))
      x when (var? x) ->
        (cdr (assv x, rho))
    end
  end

  # 7.3.2 Eliminators

  @spec do_car(value) :: value
  @spec do_cdr(value) :: value

  def (do_car v) do
    case v do
      (pair a, _d) -> a
      (neu (sigma tA, _), ne) ->
        (neu tA, (n_car ne))
    end
  end

  def (do_cdr v) do
    case v do
      (pair _a, d) -> d
      (neu (sigma _, tD), ne) ->
        (neu (val_of_closure tD, (do_car v)),
             (n_cdr ne))
    end
  end

  @spec (do_ap2 value, value) :: value
  def (do_ap2 fun, arg) do
    case fun do
      (lam c) ->
        (val_of_closure c, arg)
      (neu (pi tA, tB), ne) ->
        (neu (val_of_closure tB, arg),
             (n_ap ne, (the tA, arg)))
    end
  end

  @spec (do_ind_Absurd value, value) :: value
  def (do_ind_Absurd target, motive) do
    case target do
      (neu absurd(), ne) ->
        (neu motive, (n_ind_Absurd ne, (the uni(), motive)))
    end
  end

  @spec (do_replace value, value, value) :: value
  def (do_replace target, motive, base) do
    case target do
      same() -> base
      (neu (eq tA, from, to), ne) ->
        (neu (do_ap2 motive, to),
          (n_replace ne,
            (the (pi tA, (h_o_clos :x, fn _ -> uni() end)),
              motive),
            (the (do_ap2 motive, from),
              base)))
    end
  end

  @spec (do_ind_Nat value, value, value, value) :: value
  @spec (ind_Nat_step_type value) :: value

  def (do_ind_Nat target, motive, base, step) do
    case target do
      zero() -> base
      (add1 n) -> (do_ap2 (do_ap2 step, n), (do_ind_Nat n, motive, base, step))
      (neu nat(), ne) ->
        (neu (do_ap2 motive, target),
          (n_ind_Nat ne,
            (the (pi nat(),
              (h_o_clos :k, fn _k -> uni() end)),
              motive),
            (the (do_ap2 motive, zero()), base),
            (the (ind_Nat_step_type motive),
              step)))
    end
  end

  def (ind_Nat_step_type motive) do
    (pi nat(),
      (h_o_clos :n_1,
        (fn n_1 -> 
          (pi (do_ap2 motive, n_1),
            (h_o_clos :ih, (fn _ih ->
              (do_ap motive, (add1 n_1)) end))) end)))
  end

  # 7.3.3 Reading Back

  @spec (read_back_norm context, norm) :: expression
  def (read_back_norm g, norm) do
    case norm do
      (the nat(), zero()) -> :zero
      (the nat(), (add1 n)) ->
        [:add1, (read_back_norm g, (the nat(), n))]
      (the (pi tA, tB), f) ->
        x = (closure_name tB)
        y = (freshen (Enum.map g, &car/1), x)
        y_val = (neu tA, (n_var y))
        [:λ, [y],
          (read_back_norm (extend_ctx g, y, tA),
            (the (val_of_closure tB, y_val),
              (do_ap2 f, y_val)))]
      (the (sigma tA, tD), p) ->
        the_car = (the tA, (do_car p))
        the_cdr = (the (val_of_closure tD, the_car), (do_cdr p))
        [:cons, (read_back_norm g, the_car), (read_back_norm g, the_cdr)]
      (the trivial(), _) -> :sole
      (the absurd(), (neu absurd(), ne)) ->
        [:the, :Absurd,
          (read_back_neutral g, ne)]
      (the (eq _ta, _from, _to), same()) -> :same
      (the atom!(), (quote! x)) -> x
      (the uni(), nat()) -> :Nat
      (the uni(), atom!()) -> :Atom
      (the uni(), trivial()) -> :Trivial
      (the uni(), absurd()) -> :Absurd
      (the uni(), (eq tA, from, to)) ->
        [:=, (read_back_norm g, (the uni(), tA)),
          (read_back_norm g, (the tA, from)),
          (read_back_norm g, (the tA, to))]
      (the uni(), (sigma tA, tD)) ->
        x = (closure_name tD)
        y = (freshen (map &car/1, g), x)
        [:Σ, [{y, (read_back_norm g, (the uni(), tA))}],
          (read_back_norm (extend_ctx g, y, tA),
            (the uni(), (val_of_closure tD, (neu tA, (n_var y)))))]
      (the uni(), (pi tA, tB)) ->
        x = (closure_name tB)
        y = (freshen (map &car/1, g), x)
        [:Π, [{y, (read_back_norm g, (the uni(), tA))}],
          (read_back_norm (extend_ctx g, y, tA),
            (the uni(), (val_of_closure tB, (neu tA, (n_var y)))))]
      (the uni(), uni()) -> :U
      (the _t1, (neu _t2, ne)) ->
        (read_back_neutral g, ne)
    end
  end

  @spec (read_back_neutral context, neutral) :: expression
  def (read_back_neutral g, neu) do
    case neu do
      (n_var x) -> x
      (n_ap ne, rand) ->
        [(read_back_neutral g, ne),
          (read_back_norm g, rand)]
      (n_car ne) -> [:car, (read_back_neutral g, ne)]
      (n_cdr ne) -> [:cdr, (read_back_neutral g, ne)]
      (n_ind_Nat ne, motive, base, step) ->
        [:ind_Nat, (read_back_neutral g, ne),
          (read_back_norm g, motive),
          (read_back_norm g, base),
          (read_back_norm g, step)]
      (n_replace ne, motive, base) ->
        [:replace, (read_back_neutral g, ne),
          (read_back_norm g, motive),
          (read_back_norm g, base)]
      (n_ind_Absurd ne, motive) ->
        [:ind_Absurd, [:the, :Absurd, (read_back_neutral g, ne)],
          (read_back_norm g, motive)]
    end
  end

  # 7.4 Type Checking

  # 7.4.1 The Type Checker

  @type elab :: any # [:the, expression, expression]
  @spec (synth2 context, expression) :: elab
  def (synth2 g, e) do
    view e do
      [:the, type, expr] ->
        (go_on [[t_out, (check2 g, type, uni())],
          [e_out, (check2 g, expr, (val (ctx2env g), t_out))]],
          (go [:the, t_out, e_out]))
      :U ->
        (go [:the, :U, :U])
      [op, [{x, tA}], tD] when op in [:Σ, :Sigma] ->
        (go_on [[ta_out, (check2 g, tA, uni())],
          [td_out, (check2 (extend_ctx g, x, (val (ctx2env g), ta_out)), tD, uni())]],
          (go [:the, :U, [:Σ, [{x, ta_out}], td_out]]))
      [:car, pr] ->
        (go_on [[[:the, pr_ty, pr_out], (synth2 g, pr)]],
          (case (val (ctx2env g), pr_ty) do
            (sigma tA, tD) ->
              (go [:the, (read_back_norm g, (the uni(), tA)), [:car, pr_out]])
            non_sigma ->
              (stop e, "Expected Σ, got #{
                (read_back_norm g, (the uni(), non_sigma))}")
          end))
      [:cdr, pr] ->
        (go_on [[[:the, pr_ty, pr_out], (synth2 g, pr)]],
          (case (val (ctx2env g), pr_ty) do
            (sigma tA, tD) ->
              the_car = (do_car (val (ctx2env g), pr_out))
              (go [:the, (read_back_norm g, (the uni(), (val_of_closure tD, the_car))), [:cdr, pr_out]])
            non_sigma ->
              (stop e, "Expected Σ, got #{inspect(
                (read_back_norm g, (the uni(), non_sigma)))}")
          end))
      :Nat -> (go [:the, :U, :Nat])
      [:ind_Nat, target, motive, base, step] ->
        (go_on [[target_out, (check2 g, target, nat())],
          [motive_out, (check2 g, motive, (pi nat(), (h_o_clos :n, fn _ -> uni() end)))],
          [motive_val, (go (val (ctx2env g), motive_out))],
          [base_out, (check2 g, base, (do_ap motive_val, zero()))],
          [step_out, (check2 g,
            step,
            (ind_Nat_step_type motive_val))]
        ],
          (go [:the, (read_back_norm g,
          (the uni(),
            (do_ap motive_val, (val (ctx2env g), target_out)))),
            [:ind_Nat, target_out, motive_out, base_out, step_out]]))
      [:=, tA, from, to] ->
        (go_on [[tA_out, (check2 g, tA, uni())],
          [tA_val, (go (val (ctx2env g), tA_out))],
          [from_out, (check2 g, from, tA_val)],
          [to_out, (check2 g, to, tA_val)]],
          (go [:the, :U, [:=, tA_out, from_out, to_out]]))
      [:replace, target, motive, base] ->
        (go_on [[[:the, target_t, target_out], (synth2 g, target)]],
          (case (val (ctx2env g), target_t) do
            (eq tA, from ,to) ->
              (go_on [[motive_out,
                (check2 g,
                  motive,
                  (pi tA, (h_o_clos :x, (fn _x -> uni() end))))],
                [motive_v, (go (val (ctx2env g), motive_out))],
                [base_out, (check2 g, base, (do_ap motive_v, from))]
              ],
                (go [:the, (read_back_norm g, (the uni(), (do_ap motive_v, to))),
                  [:replace, target_out, motive_out, base_out]]))
            non_eq ->
              (stop target, "Expected =, but type is #{inspect(non_eq)}")
          end))
      [op, [{x, tA}], tB] when op in [:Π, :Pi] ->
        (go_on [[tA_out, (check2 g, tA, uni())],
          [tB_out, (check2 (extend_ctx g, x, (val (ctx2env g), tA_out)), tB, uni())]],
          (go [:the, :U, [:Π, [{x, tA_out}], tB_out]]))
      :Trivial -> (go [:the, :U, :Trivial])
      :Absurd -> (go [:the, :U, :Absurd])
      [:ind_Absurd, target, motive] ->
        (go_on [[target_out, (check2 g, target, absurd())],
          [motive_out, (check2 g, motive, uni())]],
          (go [:the, motive_out, [:ind_Absurd, target_out, motive_out]]))
      :Atom -> (go [:the, :U, :Atom])
      [rator, rand] ->
        (go_on [[[:the, rator_t, rator_out], (synth2 g, rator)]],
          (case (val (ctx2env g), rator_t) do
            (pi tA, tB) ->
              (go_on [[rand_out, (check2 g, rand, tA)]],
                (go [:the, (read_back_norm g,
                (the uni(), (val_of_closure tB,
                  (val (ctx2env g), rand_out)))),
                [rator_out, rand_out]]))
            non_pi -> (stop rator,
              "Expected a Π type, but this is a #{
              inspect((read_back_norm g, (the uni(), non_pi)))}")
          end))
      x when (var? x) ->
        (go_on [[t, (lookup_type x, g)]],
          (go [:the, (read_back_norm g, (the uni(), t)), x]))
      _none_of_the_above -> (stop e, "Can't synthesize a type")
    end
  end

  @spec (check2 context, expression, value) :: perhaps(expression)
  def check2(g, e, t) do
    case e do
      [:cons, a, d] ->
        case t do
          (sigma tA, tD) ->
            (go_on [[a_out, (check2 g, a, tA)],
            [d_out, (check2 g, d, (val_of_closure tD, (val (ctx2env g), a_out)))]],
              (go [:cons, a_out, d_out]))
          non_sigma -> (stop e, "Expected Σ, got #{inspect(
            (read_back_norm g, (the uni(), non_sigma)))}")
        end
      :zero ->
        case t do
          nat() -> (go :zero)
          non_nat -> (stop e, "Expected Nat, got #{inspect(
            (read_back_norm g, (the uni(), non_nat)))}")
        end
      [:add1, n] ->
        case t do
          nat() ->
            (go_on [[n_out, (check2 g, n, nat())]],
              (go [:add1, n_out]))
          non_nat -> (stop e, "Expected Nat, got #{inspect(
            (read_back_norm g, (the uni(), non_nat)))}")
        end
      :same ->
        case t do
          (eq tA, from, to) ->
            (go_on [[_, (convert g, tA, from, to)]],
              (go :same))
          non_eq -> (stop e, "Expected =, got #{inspect(
            (read_back_norm g, (the uni(), non_eq)))}")
        end
      :sole ->
        case t do
          trivial() -> (go :sole)
          non_trivial -> (stop e, "Expected Trivial, got #{inspect(
            (read_back_norm g, (the uni(), non_trivial)))}")
        end
      [op, [x], b] when op in [:λ, :lambda] ->
        case t do
          (pi tA, tB) ->
            x_val = (neu tA, (n_var x))
            (go_on [[b_out, (check2 (extend_ctx g, x, tA), b, (val_of_closure tB, x_val))]],
            (go [:λ, [x], b_out]))
        end
      a when is_atom(a) ->
        case t do
          atom!() ->
            (go a)
          non_atom -> (stop e, "Expected Atom, got #{inspect(
            (read_back_norm g, (the uni(), non_atom)))}")
        end
      _none_of_the_above ->
        (go_on [[[:the, t_out, e_out], (synth2 g, e)],
          [_, (convert g, uni(), t, (val (ctx2env g), t_out))]],
          (go e_out))
    end
  end

  @spec (convert context, value, value, value) :: perhaps(:ok)
  def (convert g, t, v1, v2) do
    e1 = (read_back_norm g, (the t, v1))
    e2 = (read_back_norm g, (the t, v2))
    if (α_equiv? e1, e2) do
      (go :ok)
    else
      tn = (read_back_norm g, (the uni(), t))
      (stop e1, "Expected to be the same #{inspect(tn)} as #{inspect(e2)}")
    end
  end

  # 7.4.2 Type Checking with Definition
end
