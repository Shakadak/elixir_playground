defmodule Ast.Core.Typed do
  defmacro var_t(id, type) do
    quote do {
      :var,
      unquote(id),
      unquote(type),
    } end
  end

  defmacro lit_t(literal, type) do
    quote do {
      :lit,
      unquote(literal),
      unquote(type),
    } end
  end

  defmacro app_t(expr, args, type) do
    quote do {
      :app,
      unquote(expr),
      unquote(args),
      unquote(type),
    } end
  end

  defmacro lam_t(args, expr, type) do
    quote do {
      :lam,
      unquote(args),
      unquote(expr),
      unquote(type),
    } end
  end

  defmacro let_t(bind, expr, type) do
    quote do {
      :let,
      unquote(bind),
      unquote(expr),
      unquote(type),
    } end
  end

  defmacro rec_t(bind, expr, type) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
      unquote(type),
    } end
  end

  defmacro non_rec_t(bind, expr, type) do
    quote do {
      :non_rec,
      unquote(bind),
      unquote(expr),
      unquote(type),
    } end
  end

  defmacro case_t(exprs, clauses, type) do
    quote do {
      :case,
      unquote(exprs),
      unquote(clauses),
      unquote(type),
    } end
  end

  defmacro clause_t(pats, guards, expr, type) do
    quote do {
      :clause,
      unquote(pats),
      unquote(guards),
      unquote(expr),
      unquote(type),
    } end
  end
end
