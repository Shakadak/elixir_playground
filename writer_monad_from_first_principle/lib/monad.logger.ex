defmodule Monad.Logger do
  @enforce_keys [:run_logger]
  defstruct [:run_logger]

  def new({x, _} = t) when is_list(x), do: %Monad.Logger{run_logger: t}

  def pure(x), do: new({[], x})

  def log(s), do: new({[s], {}})

  def logs(ss), do: new({ss, {}})

  def map(ma, f)  do
    {logs, x} = ma.run_logger
    new({logs, f.(x)})
  end

  def ap(mf, ma) do
    {log1, f} = mf.run_logger
    {log2, x} = ma.run_logger
    new({log1 ++ log2, f.(x)})
  end

  def lift_a(mf, ma) do
    {log1, f} = mf.run_logger
    {log2, x} = ma.run_logger
    new({log1 ++ log2, f.(x)})
  end

  def lift_a2(mf, ma, mb) do
    {log1, f} = mf.run_logger
    {log2, x} = ma.run_logger
    {log3, y} = mb.run_logger
    new({log1 ++ log2 ++ log3, f.(x, y)})
  end

  def lift_a3(mf, ma, mb, mc) do
    {log1, f} = mf.run_logger
    {log2, x} = ma.run_logger
    {log3, y} = mb.run_logger
    {log4, z} = mc.run_logger
    new({log1 ++ log2 ++ log3 ++ log4, f.(x, y, z)})
  end

  def join(mma) do
    {log_out, ma} = mma.run_logger
    {log_in, x} = ma.run_logger
    new({log_out ++ log_in, x})
  end

  def bind(ma, f) do
    {log_out, x} = ma.run_logger
    {log_in, y} = f.(x).run_logger
    new({log_out ++ log_in, y})
  end

  defimpl Inspect, for: Monad.Logger do
    def inspect(%Monad.Logger{run_logger: {logs, x}}, opts), do: Inspect.Algebra.concat(["(", Inspect.Algebra.to_doc(logs, opts), ", ", Inspect.Algebra.to_doc(x, opts), ")"])
  end

  defmacro m(do: {:__block__, _context, body}) do
    rec_mdo(body)
  end

  def rec_mdo([{:<-, context, _}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic do should be a monadic value"
  end

  def rec_mdo([line]) do
    line
  end

  def rec_mdo([{:<-, _context, [binding, expression]} | tail]) do
    quote do
      case unquote(expression) do
        %Monad.Logger{run_logger: {log7, unquote(binding)}} ->
          case unquote(rec_mdo(tail)) do
            %Monad.Logger{run_logger: {log8, a8}} ->
              new({log7 ++ log8, a8})
          end
      end
    end
  end

  def rec_mdo([{:=, _context, [_binding, _expression]} = line | tail]) do
    quote do
      unquote(line)
      unquote(rec_mdo(tail))
    end
  end

  def rec_mdo([expression | tail]) do
    quote do
      case unquote(expression) do
        %Monad.Logger{run_logger: {log7, a7}} ->
          case unquote(rec_mdo(tail)) do
            %Monad.Logger{run_logger: {log8, a8}} ->
              new({log7 ++ log8, a8})
          end
      end
    end
  end
end
