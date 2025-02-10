defmodule Parser.Op do
  @enforce_keys [:op]
  defstruct @enforce_keys
end

defmodule Parser do
  @enforce_keys [:satisfy]
  defstruct @enforce_keys

  use Eff

  import Amb
  import Exn
  import Local

  def satisfy, do: %Parser.Op{op: :satisfy}

  def choice(p1, p2) do
    m Eff do
      b <- perform flip(), {}
      if b do p1 else p2 end
    end
  end

  def many(p) do
    choice(many1(p), pure([]))
  end

  def many1(p) do
    m Eff do
      x <- p
      xs <- many(p)
      pure([x | xs])
    end
  end

  def parse(input, action) do
    handler = %Parser{
      satisfy: operation(fn p, k ->
        m Eff do
          input <- perform lget(), {}
          case p.(input) do
            Nothing -> perform failure(), {}
            {Just, {x, rest}} -> m Eff do
              perform lput(), rest
              k.(x)
            end
          end
        end
      end)
    }
    handlerLocalRet(input, fn x, s -> {x, s} end, handler, action)
  end

  def symbol(c) do
    perform satisfy(), fn input ->
      case input do
        [d | rest] when d == c -> {Just, {c, rest}}
        _ -> Nothing
      end
    end
  end

  def digit do
    perform satisfy(), fn input -> case input do
      [d | rest] when d in ?0..?9 -> {Just, {d - ?0, rest}}
      _ -> Nothing
    end end
  end

  def expr do
    choice(m Eff do
      i <- term() ; symbol(?+) ; j <- term()
      pure(i + j)
    end, term())
  end

  def term do
    choice(m Eff do
      i <- factor() ; symbol(?*) ; j <- factor()
      pure(i * j)
    end, factor())
  end

  def factor do
    choice(m Eff do
      symbol(?() ; i <- expr() ; symbol(?))
      pure(i)
    end, number())
  end

  def number do
    m Eff do
      xs <- many1(digit())
      pure(Enum.reduce(xs, 0, fn d, n -> 10 * n + d end))
    end
  end

  def catMaybes(xs) do
    Enum.flat_map(xs, fn
      {Just, x} -> [x]
      Nothing -> []
    end)
  end

  def solutions(action) do
    map(&catMaybes/1, allResults(toMaybe(action)))
  end

  def eager(action) do
    firstResult(toMaybe(action))
  end
end

defimpl Context, for: Parser.Op do
  def appropriate?(_, %Parser{}) do true end
  def appropriate?(_, _) do false end

  def selectOp(_, %Parser{satisfy: op}) do op end
end
