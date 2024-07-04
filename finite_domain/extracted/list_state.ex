defmodule Elixir.Wrapped.ListState do
  def liftA2(f, mx, my) do
    ap(map(mx, fn x1 -> fn y -> f.(x1, y) end end), my)
  end

  def ap(mf, mx) do
    fn s ->
      Enum.flat_map( mf.(s), fn {f, s1} ->
        Enum.flat_map( mx.(s1), fn {x, s2} ->
          [{f.(x), s2}]
        end)
      end)
    end
  end

  def bind(m, k) do
    fn s ->
      Enum.flat_map( m.(s), fn {a, s2} -> k.(a).(s2) end)
    end
  end

  def evalStateT(m, s) do
    Enum.flat_map( m.(s), fn {a, _} -> [a] end)
  end

  def execStateT(m, s) do
    Enum.flat_map( m.(s), fn {_, s2} -> [s2] end)
  end

  def leftA(ml, mr) do
    liftA2(fn l, _r -> l end, ml, mr)
  end

  def leftM(ml, mr) do
    bind(ml, fn _ -> mr end)
  end

  def map(m, f) do
    fn s -> Enum.map(m.(s), fn {a, s2} -> {f.(a), s2} end) end
  end

  def mapM( [], _) do
    pure([])
  end

  def mapM( [x | xs], f) do
    bind(f.(x), fn y -> bind(mapM(xs, f), fn ys -> pure([y | ys]) end) end)
  end

  def mapM_( [], _) do
    pure({})
  end

  def mapM_( [x | xs], f) do
    bind(f.(x), fn _ -> mapM_(xs, f) end)
  end

  def mapStateT(m, f) do
    fn s -> f.(m.(s)) end
  end

  def mplus(ml, mr) do
    fn s -> :erlang.++(ml.(s), mr.(s)) end
  end

  def replicateM( 0, _) do
    pure([])
  end

  def replicateM(n, m) when :erlang.andalso(:erlang.is_integer(n), :erlang.>(n, 0)) do
    bind(m, fn x -> bind(replicateM(:erlang.-(n, 1), m), fn xs -> pure([x | xs]) end) end)
  end

  def rightA(ml, mr) do
    liftA2(fn _l, r -> r end, ml, mr)
  end

  defmacro whenM(cnd, m) do
    {:case, [],
     [
       cnd,
       [
         do: [
           {:->, [], [[true], m]},
           {:->, [], [[false], {{:., [], [Wrapped.ListState, :pure]}, [], [{:{}, [], []}]}]}
         ]
       ]
     ]}
  end

  def withStateT(m, f) do
    fn s -> m.(f.(s)) end
  end

  def gets(f) do
    state(fn s -> {f.(s), s} end)
  end

  def guard(true) do
    pure({})
  end

  def guard(false) do
    mzero()
  end

  def lift(m) do
    fn s -> Enum.flat_map(m, fn a -> [{a, s}] end) end
  end

  def modify(f) do
    state(fn s -> {{}, f.(s)} end)
  end

  def pure(a) do
    fn s -> [{a, s}] end
  end

  def put(s) do
    state(fn _ -> {{}, s} end)
  end

  def state(f) do
    fn s -> [f.(s)] end
  end

  def get do
    gets(fn x1 -> x1 end)
  end

  def mzero do
    fn _ -> [] end
  end
end
