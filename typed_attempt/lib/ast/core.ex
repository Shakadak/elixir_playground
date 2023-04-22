defmodule Ast.Core do
  defmacro var(id) do
    quote do {
      :var,
      unquote(id),
    } end
  end

  defmacro lit(literal) do
    quote do {
      :lit,
      unquote(literal),
    } end
  end

  defmacro app(expr, args) do
    quote do {
      :app,
      unquote(expr),
      unquote(args),
    } end
  end

  defmacro lam(args, expr) do
    quote do {
      :lam,
      unquote(args),
      unquote(expr),
    } end
  end

  defmacro let(bind, expr) do
    quote do {
      :let,
      unquote(bind),
      unquote(expr),
    } end
  end

  defmacro rec(bind, expr) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
    } end
  end

  defmacro non_rec(bind, expr) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
    } end
  end

  defmacro case(exprs, clauses) do
    quote do {
      :case,
      unquote(exprs),
      unquote(clauses),
    } end
  end

  defmacro clause(pats, guards, expr) do
    quote do {
      :clause,
      unquote(pats),
      unquote(guards),
      unquote(expr),
    } end
  end
end
