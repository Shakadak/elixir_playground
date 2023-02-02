defmodule Ast do
  defmacro clause(pattern, guard, expression) do
    quote do {
      :clause,
      unquote(pattern),
      unquote(guard),
      unquote(expression),
    } end
  end

  defmacro match(pattern, expression) do
    quote do {
      :match,
      unquote(pattern),
      unquote(expression),
    } end
  end

  defmacro application(function, arguments) do
    quote do {
      :application,
      unquote(function),
      unquote(arguments),
    } end
  end

  defmacro literal(value) do
    quote do {
      :literal,
      unquote(value),
    } end
  end

  defmacro identifier(value) do
    quote do {
      :identifier,
      unquote(value),
    } end
  end
end
