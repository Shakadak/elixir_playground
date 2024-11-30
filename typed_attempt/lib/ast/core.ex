defmodule Ast.Core do
  defmacro var(id) do
    quote do {
      :var,
      unquote(id),
      :_?,
    } end
  end

  defmacro lit(literal) do
    quote do {
      :lit,
      unquote(literal),
      :_?,
    } end
  end

  defmacro app(expr, args) do
    quote do {
      :app,
      unquote(expr),
      unquote(args),
      :_?,
    } end
  end

  defmacro lam(args, expr) do
    quote do {
      :lam,
      unquote(args),
      unquote(expr),
      :_?,
    } end
  end

  defmacro let(bind, expr) do
    quote do {
      :let,
      unquote(bind),
      unquote(expr),
      :_?,
    } end
  end

  defmacro rec(bind, expr) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
      :_?,
    } end
  end

  defmacro non_rec(bind, expr) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
      :_?,
    } end
  end

  defmacro case(exprs, clauses) do
    quote do {
      :case,
      unquote(exprs),
      unquote(clauses),
      :_?,
    } end
  end

  defmacro clause(pats, expr) do
    quote do {
      :clause,
      unquote(pats),
      unquote([]),
      unquote(expr),
      :_?,
    } end
  end

  defmacro gclause(pats, guards, expr) do
    quote do {
      :clause,
      unquote(pats),
      unquote(guards),
      unquote(expr),
      :_?,
    } end
  end
end
