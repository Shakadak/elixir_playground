defmodule Control.RwsT do

  @enforce_keys [:unRwsT]
  defstruct [:unRwsT]

  # rwsT :: ((r, s, [w]) -> m (a, s, [w])) -> RwsT r w s m a
  def new(f) when is_function(f, 3) do
    %__MODULE__{unRwsT: f}
  end

  defmacro mk(dict) do
    quote location: :keep do

      alias ComputationExpression, as: CE
      require CE

      # rwsT :: (r, s -> Result (a, s, [w])) -> RwsT r w s m a
      def rwsT(f) do
        Control.RwsT.new fn r, s, w ->
          unquote(dict).map(f.(r, s), fn {a, s2, w2} ->
            {a, s2, w ++ w2}
          end)
        end 
      end

      # runRwsT :: RwsT r w s a, r, s -> Result (a, s, [w])
      def runRwsT(m, r, s), do: m.unRwsT.(r, s, [])

      # evalRwsT ::
      #          RwsT r w s m a     -- ^computation to execute
      #          , r                -- ^initial environment
      #          , s                -- ^initial value
      #          -> m {a, [w]}      -- ^computation yielding final value and output
      def evalRwsT(m, r, s) do
        CE.compute unquote(dict) do
          let! {a, _, w} = runRwsT(m, r, s)
          pure {a, w}
        end
      end

      # execRwsT ::
      #          RwsT r w s m a      -- ^computation to execute
      #          , r                 -- ^initial environment
      #          , s                 -- ^initial value
      #          -> m {s, [w]}       -- ^computation yielding final state and output
      def execRwsT(m, r, s) do
        CE.compute unquote(dict) do
          let! {_, s2, w} = runRwsT(m, r, s)
          pure {s2, w}
        end
      end

      # mapRwsT :: RwsT r w s a, (Result (a, s, [w]) -> n (b, s, [w'])), MonadDict n -> nRwsT r w' s b
      def mapRwsT(m, f, dict_n) do
        Control.RwsT.new fn r, s, w ->
          CE.compute dict_n do
            let! {a, s2, w2} = f.(runRwsT(m, r, s))
            pure {a, s2, w ++ w2}
          end
        end
      end

      # withRwsT :: RwsT r w s a, (r' -> s -> (r, s)) -> RwsT r' w s a
      def withRwsT(m, f) do
        Control.RwsT.new fn r, s, w ->
          {r2, s2} = f.(r, s)
          m.unRwsT.(r2, s2, w)
        end
      end

      # map :: RwsT r w s a, (a -> b) -> RwsT r w s b
      def map(m, f) do
        Control.RwsT.new fn r, s, w ->
          unquote(dict).map(m.unRwsT.(r, s, w), fn {a, s2, w2} -> {f.(a), s2, w2} end)
        end
      end

      # pure :: a -> RwsT r w s a
      def pure(a) do
        Control.RwsT.new fn _, s, w ->
          unquote(dict).pure({a, s, w})
        end
      end

      def bind(m, k) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {a, s2, w2} = m.unRwsT.(r, s, w)
            k.(a).unRwsT.(r, s2, w2)
          end
        end
      end

      def lift(m) do
        Control.RwsT.new fn _, s, w ->
          CE.compute unquote(dict) do
            let! a = m
            pure {a, s, w}
          end
        end
      end

      ### Reader operations ------------------------------------------------------------------

      def reader(f), do: asks(f)

      def ask, do: asks(& &1)

      def local(f, m) do
        Control.RwsT.new fn r, s, w -> m.unRwsT.(f.(r), s, w) end
      end

      # asks :: (Monad m) => (r -> a) -> RwsT r w s m a
      def asks(f) do
        Control.RwsT.new fn r, s, w ->
          unquote(dict).pure {f.(r), s, w}
        end
      end

      ### Writer operations ------------------------------------------------------------------

      # writer :: {a, [w]} -> RwsT r w s a
      def writer({a, w2}) do
        Control.RwsT.new fn _, s, w ->
          unquote(dict).pure {a, s, w ++ w2}
        end
      end

      # tell :: [w] -> RwsT r w s ()
      def tell(w2), do: writer({{}, w2})

      # listen :: RwsT r w s a -> RwsT r w s (a, w)
      def listen(m), do: listens(m, & &1)

      # listens :: RwsT r w s a -> ([w] -> b) -> RwsT r w s (a, b)
      def listens(m, f) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {a, s2, w2} = runRwsT(m, r, s)
            pure {{a, f.(w2)}, s2, w ++ w2}
          end
        end
      end

      # pass :: RwsT r w s (a, [w] -> [w']) -> RwsT r w' s a
      def pass(m) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {{a, f}, s2, w2} = runRwsT(m, r, s)
            pure {a, s2, w ++ f.(w2)}
          end
        end
      end

      # censor :: RwsT r w s a -> ([w] -> [w]) -> RwsT r w s a
      def censor(m, f) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {a, s2, w2} = runRwsT(m, r, s)
            pure {a, s2, w ++ f.(w2)}
          end
        end
      end
    end
  end
end
