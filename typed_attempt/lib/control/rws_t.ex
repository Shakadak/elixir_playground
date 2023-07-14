defmodule Control.RwsT do

  @enforce_keys [:unRwsT]
  defstruct [:unRwsT]

  # rwsT :: ((r, s, [w]) -> m (a, s, [w])) -> RwsT r w s m a
  def new(f) when is_function(f, 3) do
    %__MODULE__{unRwsT: f}
  end

  defmacro mk(dict) do
    require_ast =
      if is_atom(Macro.expand_literals(dict, __CALLER__)) do
        quote do require unquote(dict) end
      end

    quote location: :keep do

      alias ComputationExpression, as: CE
      require CE

      unquote(require_ast)

      @doc """
      Construct an RwsT computation from a function.
      (The inverse of `runRwsT`.)

      ```
      rwsT :: Functor m => (r, s -> m (a, s, [w])) -> RwsT r w s m a
      ```
      """
      def rwsT(f) do
        Control.RwsT.new fn r, s, w ->
          unquote(dict).map(f.(r, s), fn {a, s2, w2} ->
            {a, s2, w ++ w2}
          end)
        end
      end

      @doc """
      Unwrap an RwsT computation as a function.
      (The inverse of `rwsT`.)

      ```
      runRwsT :: RwsT r w s a, r, s -> Result (a, s, [w])
      ```
      """
      def runRwsT(m, r, s), do: m.unRwsT.(r, s, [])

      @doc """
      Evaluate a computation with the given initial state and environment,
      returning the final value and output, discarding the final state.

      ```
      evalRwsT :: Monad m
               => RwsT r w s m a     -- ^computation to execute
               -> r                -- ^initial environment
               -> s                -- ^initial value
               -> m {a, [w]}      -- ^computation yielding final value and output
      ```
      """
      def evalRwsT(m, r, s) do
        CE.compute unquote(dict) do
          let! {a, _, w} = runRwsT(m, r, s)
          pure {a, w}
        end
      end

      @doc """
      Evaluate a computation with the given initial state and environment,
      returning the final state and output, discarding the final value.

      ```
      execRwsT :: Monad m
               => RwsT r w s m a  -- ^computation to execute
               -> r               -- ^initial environment
               -> s               -- ^initial value
               -> m {s, [w]}      -- ^computation yielding final state and output
      ```
      """
      def execRwsT(m, r, s) do
        CE.compute unquote(dict) do
          let! {_, s2, w} = runRwsT(m, r, s)
          pure {s2, w}
        end
      end

      @doc """
      Map the inner computation using the given function.

      ```
      runRwsT(mapRwsT(m, f), r, s) = f.(runRwsT(m, r, s)
      ```

      ```
      mapRwsT :: (Monad m, Monad n) => RwsT r w s m a -> (m (a, s, [w]) -> n (b, s, [w'])) -> MonadDict n -> RwsT r w' s n b
      ```
      """
      def mapRwsT(m, f, dict_n) do
        Control.RwsT.new fn r, s, w ->
          CE.compute dict_n do
            let! {a, s2, w2} = f.(runRwsT(m, r, s))
            pure {a, s2, w ++ w2}
          end
        end
      end

      @doc """
      `withRwsT(m, f)` executes action `m` with an initial environment
      and state modified by applying `f`.

      ```
      withRwsT :: RwsT r w s m a -> (r' -> s -> (r, s)) -> RwsT r' w s m a
      ```
      """
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

      @doc """
      Constructor for computations in the reader monad (equivalent to `asks/1`).

      ```
      reader :: Monad m => (r -> a) -> RWST r w s m a
      ```
      """
      def reader(f), do: asks(f)

      @doc """
      Fetch the value of the environment.

      ```
      ask :: Monad m => RwsT r w s m r
      ```
      """
      def ask, do: asks(& &1)

      @doc """
      Execute a computation in a modified environment.

      ```
      runRwsT(local(f, m), r, s) = runRwsT(m, f.(r), s)
      ```

      ```
      local :: (r -> r) -> RwsT r w s m a -> RwsT r w s m a
      ```
      """
      def local(f, m) do
        Control.RwsT.new fn r, s, w -> m.unRwsT.(f.(r), s, w) end
      end

      @doc """
      Retrieve a function of the current environment.

      ```
      asks(f) = map(ask(), f)
      ```

      ```
      asks :: Monad m => (r -> a) -> RwsT r w s m a
      ```
      """
      def asks(f) do
        Control.RwsT.new fn r, s, w ->
          unquote(dict).pure {f.(r), s, w}
        end
      end

      ### Writer operations ------------------------------------------------------------------

      @doc """
      Construct a writer computation from a `{result, output}` pair.

      ```
      writer :: Monad m => {a, [w]} -> RwsT r w s m a
      ```
      """
      def writer({a, w2}) do
        Control.RwsT.new fn _, s, w ->
          unquote(dict).pure {a, s, w ++ w2}
        end
      end

      @doc """
      `tell(w)` is an action that produce the output `w`.

      ```
      tell :: Monad m => [w] -> RwsT r w s m ()
      ```
      """
      def tell(w2), do: writer({{}, w2})

      @doc """
      `listen(m)` is an action that ececutes the action `m` and adds its
      output to the value of the computation.

      ```
      runRwsT(listen(m), r, s) = map(runRwsT(m, r, s), fn {a, w} -> {{a, w}, w} end)
      ```

      ```
      listen :: Monda m => RwsT r w s m a -> RwsT r w s m (a, w)
      ```
      """
      def listen(m), do: listens(m, & &1)

      @doc """
      `listens(m, f)` is an action that executes the action `m` and adds
      the result of applying `f` to the output to the value of the computation.

      ```
      listens(m, f) = map(listen(m), fn {a, w} -> {a, f.(w)} end)
      ```

      ```
      runRwsT(listens(m, f), r, s) = map(runRWST(m, r, s), fn {a, w} -> {{a, f.(w)}, w} end)
      ```

      ```
      listens :: Monad m => RwsT r w s m a -> ([w] -> b) -> RwsT r w s m (a, b)
      ```
      """
      def listens(m, f) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {a, s2, w2} = runRwsT(m, r, s)
            pure {{a, f.(w2)}, s2, w ++ w2}
          end
        end
      end

      @doc """
      `pass(m)` is an action that executes the action `m`, which returns
      a value and a function, and returns the value, applying the function
      to the output.

      ```
      runRwsT(pass(m), r, s) = map(runRwsT(m, r, s), fn {{a, f}, w} -> {a, f.(w)} end)
      ```

      ```
      pass :: Monad m => RwsT r w s m (a, [w] -> [w']) -> RwsT r w' s m a
      ```
      """
      def pass(m) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {{a, f}, s2, w2} = runRwsT(m, r, s)
            pure {a, s2, w ++ f.(w2)}
          end
        end
      end

      @doc """
      `censor(m, f)` is an action that executes the action `m` and
      applies the function `f` to its output, leaving the return value
      unchanged.

      ```
      censor(m, f) = pass(map(m, fn x -> (x, f) end))
      ```

      ```
      runRwsT(censor(m, f), r, s) = map(runRwsT(m, r, s), fn {a, w} -> {a, f.(w)} end)
      ```

      ```
      censor :: Monad m => RwsT r w s m a -> ([w] -> [w]) -> RwsT r w s m a
      ```
      """
      def censor(m, f) do
        Control.RwsT.new fn r, s, w ->
          CE.compute unquote(dict) do
            let! {a, s2, w2} = runRwsT(m, r, s)
            pure {a, s2, w ++ f.(w2)}
          end
        end
      end

      ### State operations  ------------------------------------------------------------------

      @doc """
      Construct a state monad computation from a state transformer function.

      ```
      state :: Monad m => (s -> (a, s)) -> RWST r w s m a
      ```
      """
      def state(f) do
        Control.RwsT.new fn _, s, w ->
          {a, s2} = f.(s)
          unquote(dict).pure({a, s2, w})
        end
      end

      @doc """
      Fetch the current value of the state within the monad.

      ```
      get :: Monad m => RWST r w s m s
      ```
      """
      def get, do: gets(& &1)

      @doc """
      `put(s)` sets the state within the monad to `s`.

      ```
      put :: (Monad m) => s -> RWST r w s m ()
      ```
      """
      def put(s) do
        Control.RwsT.new fn _, _, w -> unquote(dict).pure({{}, s, w}) end
      end

      @doc """
      `modify(f)` is an action that updates the state to the result of
      applying `f` to the current state.

      ```
      modify(f) = get() |> bind(&put(f.(&1)))
      ```

      ```
      modify :: Monad m => (s -> s) -> RWST r w s m ()
      ```
      """
      def modify(f) do
        Control.RwsT.new fn _, s, w -> unquote(dict).pure({{}, f.(s), w}) end
      end

      @doc """
      Get a specific component of the state, using a projection function
      supplied.

      ```
      gets(f) = map(get(), f)
      ```

      ```
      gets :: (Monad m) => (s -> a) -> RWST r w s m a
      ```
      """
      def gets(f) do
        Control.RwsT.new fn _, s, w -> unquote(dict).pure({f.(s), s, w}) end
      end

      ### Generic operations -----------------------------------------------------------------

      def mapM([], _), do: pure([])
      def mapM([x | xs], f) do
        CE.compute __MODULE__ do
          let! y = f.(x)
          let! ys = mapM(xs, f)
          pure([y | ys])
        end
      end
    end
  end
end
