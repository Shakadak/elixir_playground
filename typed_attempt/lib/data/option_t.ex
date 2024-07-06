defmodule Data.OptionT do
  require Base.Option

  defmacro mkMap(t, x, f) do
    quote do unquote(t).map(unquote(x), &Option.map(&1, unquote(f))) end
  end

  defmacro mkPure(t, x) do
    quote do unquote(t).pure(Option.some(unquote(x))) end
  end

  defmacro mkBind(t, x, f) do
    quote do
      require ComputationExpression
      ComputationExpression.compute unquote(t) do
        let! v = unquote(x)
        case v do
          some(y) -> unquote(f).(y)
          none()  -> unquote(t).pure(none())
        end
      end
    end
  end
end
