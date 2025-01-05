defmodule Nbe do
  import Clos
  import N.Ap
  import N.Var
  import N.Rec
  import Go
  import Stop
  import The
  import Zero
  import Add1
  import Neu
  import Def

  @type environment :: Keyword.t
  @type symbol :: atom
  @type value :: any
  @type expression :: any
  @type void :: {}
  @type clos :: Clos.t
  @type neutral :: any
  @type context :: any
  @type perhaps(a) :: Go.t(a) | Stop.t
  @type type :: any
  @type definitions :: [Def.t]

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

  @spec extend(environment, symbol, value) :: environment
  def extend(p, x, v), do:
    cons({x, v}, p)

  @spec val(environment, expression) :: value
  def val(p, e) do
    case e do
      [f, [x], b] when f in [:lam, :λ] ->
        clos(p, x, b)

      x when is_atom(x) ->
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

  def zero?(n), do: n == 0

  def positive?(n), do: n > 0

  @spec to_church(non_neg_integer) :: expression
  def to_church(n) do
    cond do
      zero?(n) ->
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
          [:->, ta, tb] ->
            (go_on [[_, (check (extend gamma, x, ta), b, tb)]],
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

      (neu [:->, ta, tb], ne) ->
        (neu tb, (n_ap ne, (the ta, arg)))
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

      [:->, ta, tb] ->
        x = (freshen used_names, :x)
        [:λ, [x], (tread_back (cons x, used_names),
          tb,
          (tdo_ap value, (neu ta, (n_var x))))]
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
end
