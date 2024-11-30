defmodule Clos do
  @enforce_keys [
    :env,
    :var,
    :body,
  ]
  defstruct @enforce_keys

  def clos(env, var, body), do: %__MODULE__{env: env, var: var, body: body}

  @type environment :: Keyword.t
  @type symbol :: atom
  @type value :: any
  @type expression :: any
  @type void :: {}

  @type t :: %__MODULE__{
    env: environment,
    var: symbol,
    body: any,
  }

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

  def displayln(v), do: IO.inspect(v)

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
      [:lam, [x], b] -> clos(p, x, b)
      x when is_atom(x) ->
        xv = assv(x, p)
        if xv do
          cdr(xv)
        else
          raise "Unkown variable #{inspect(x)}"
        end

      [rator, rand] ->
        do_ap(val(p, rator), val(p, rand))
    end
  end

  @spec do_ap(t, value) :: value
  def do_ap(clos, arg) do
    case clos do
      %__MODULE__{env: p, var: x, body: b} ->
        val(extend(p, x, arg), b)
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
        displayln(val(p, e))
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
end
