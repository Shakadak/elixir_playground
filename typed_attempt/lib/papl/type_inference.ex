defmodule Papl.TypeInference do
  import Circe

  defmacro tyeq(l, r), do: quote(do: {:tyeq, unquote(l), unquote(r)})

  defmacro t_expr(e), do: quote(do: {:"t-expr", unquote(e)})
  defmacro t_con(name, fields), do: quote(do: {:"t-con", unquote(name), unquote(fields)})

  def numeric_t_con, do: t_con(:num, [])
  def boolean_t_con, do: t_con(:bool, [])

  def mk_fun_t_con(a, r), do: t_con(:fun, [a, r])

  def generate(e) do
    case e do
      x when is_integer(x) -> [tyeq(t_expr(e), numeric_t_con())]
      {x, _, ctxt} when is_atom(x) and is_atom(ctxt) -> []
      ~m/#{x} + #{y}/ -> generate_arith_binop(e, x, y)
      ~m/#{x} * #{y}/ -> generate_arith_binop(e, x, y)
      true -> [tyeq(t_expr(e), boolean_t_con())]
      false -> [tyeq(t_expr(e), boolean_t_con())]
      ~m/if #{cnd}, #{[do: thn, else: els]}/ ->
      #{:if, [], [cnd, [do: thn, else: els]]} ->
        [
          tyeq(t_expr(cnd), boolean_t_con()),
          tyeq(t_expr(thn), t_expr(els)),
          tyeq(t_expr(thn), t_expr(e)),
        ]
        ++ generate(cnd)
        ++ generate(thn)
        ++ generate(els)

      ~m/fn #{arg} -> #{body} end/ ->
        [tyeq(t_expr(e), mk_fun_t_con(t_expr(arg), t_expr(body)))]
        ++ generate(body)

      ~m/#{fun}.(#{arg})/ ->
        [tyeq(t_expr(fun), mk_fun_t_con(t_expr(arg), t_expr(e)))]
        ++ generate(fun)
        ++ generate(arg)
    end
  end

  def generate_arith_binop(e, l, r) do
    [
      tyeq(t_expr(e), numeric_t_con()),
      tyeq(t_expr(l), numeric_t_con()),
      tyeq(t_expr(r), numeric_t_con()),
    ]
    ++ generate(l)
    ++ generate(r)
  end
end
