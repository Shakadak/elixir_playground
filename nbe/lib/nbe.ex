defmodule Nbe do
  import Clos
  import N.Ap
  import N.Var
  import Go
  import Stop

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

  @spec assv(any, list(tuple)) :: tuple | false
  def assv(k, lst) do
    Keyword.fetch(lst, k)
    |> case do
      {:ok, v} -> {k, v}
      :error -> false
    end
  end

  @spec cdr(tuple) :: any
  def cdr({_, y}), do: y

  @spec car(tuple) :: any
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
    cons(cons(x, v), p)

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
end
