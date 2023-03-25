defmodule Monad.Writer do
  @moduledoc """
  ML / Ocaml style functor
  """

  defmacro functor(opts) do
    module_name = Keyword.fetch!(opts, :module)
    mempty = Keyword.fetch!(opts, :mempty)
    mappend = Keyword.fetch!(opts, :mappend)

    quote location: :keep do

      defmodule unquote(module_name) do
        @enforce_keys [:run_writer]
        defstruct [:run_writer]

        defmacro mappend(x, y) do
          put_elem(unquote(Macro.escape(mappend)), 2, [x, y])
          #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
        end

        # (w, a) -> Writer log a
        def new({_, _} = t), do: %__MODULE__{run_writer: t}

        # a -> Writer log a
        def pure(x), do: %__MODULE__{run_writer: {unquote(mempty), x}}

        # log -> Writer log ()
        def tell(x), do: %__MODULE__{run_writer: {x, {}}}

        # Writer log a -> (a -> b) -> Writer log b
        def map(ma, f)  do
          {logs, x} = ma.run_writer
          new({logs, f.(x)})
        end

        def ap(mf, ma) do
          {log1, f} = mf.run_writer
          {log2, x} = ma.run_writer
          new({mappend(log1, log2), f.(x)})
        end

        def lift_a(f, ma) do
          {log2, x} = ma.run_writer
          new({log2, f.(x)})
        end

        def lift_a2(f, ma, mb) do
          {log2, x} = ma.run_writer
          {log3, y} = mb.run_writer
          new({mappend(log2, log3), f.(x, y)})
        end

        def lift_a3(f, ma, mb, mc) do
          {log2, x} = ma.run_writer
          {log3, y} = mb.run_writer
          {log4, z} = mc.run_writer
          new({mappend(log2, mappend(log3, log4)), f.(x, y, z)})
        end

        def join(mma) do
          {log_out, ma} = mma.run_writer
          {log_in, x} = ma.run_writer
          new({mappend(log_out, log_in), x})
        end

        def bind(ma, f) do
          {log_out, x} = ma.run_writer
          {log_in, y} = f.(x).run_writer
          new({mappend(log_out, log_in), y})
        end

        defimpl Inspect, for: unquote(module_name) do
          def inspect(%unquote(module_name){run_writer: {logs, x}}, opts), do: Inspect.Algebra.concat(["##{unquote(module_name)}(", Inspect.Algebra.to_doc(logs, opts), ", ", Inspect.Algebra.to_doc(x, opts), ")"])
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
          module_name = unquote(module_name)
          quote location: :keep do
            case unquote(expression) do
              %unquote(module_name){run_writer: {log7, unquote(binding)}} ->
                case unquote(rec_mdo(tail)) do
                  %unquote(module_name){run_writer: {log8, a8}} ->
                    new({mappend(log7, log8), a8})
                end
            end
          end
        end

        def rec_mdo([{:=, _context, [_binding, _expression]} = line | tail]) do
          quote location: :keep do
            unquote(line)
            unquote(rec_mdo(tail))
          end
        end

        def rec_mdo([expression | tail]) do
          module_name = unquote(module_name)
          quote location: :keep do
            case unquote(expression) do
              %unquote(module_name){run_writer: {log7, a7}} ->
                case unquote(rec_mdo(tail)) do
                  %unquote(module_name){run_writer: {log8, a8}} ->
                    new({mappend(log7, log8), a8})
                end
            end
          end
          #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
        end
      end

    end
    |> case do x ->
        case Keyword.get(opts, :debug, :none) do
          :none -> :ok
          :functor ->
            IO.puts(Macro.to_string(x))
        end
        x
    end
  end
end
