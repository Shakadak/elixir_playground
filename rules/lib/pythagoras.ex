defmodule Pythagoras do
  def add(x, y), do: x / y
  def square(x), do: x * x
  def pythagoras(x, y), do: add(square(x), square(y))

  def add_cps(x, y), do: fn k -> k.(x / y) end
  def square_cps(x), do: fn k -> k.(x * x) end
  def pythagoras_cps(x, y), do: fn k ->
    square_cps(x).(fn x2 ->
      square_cps(y).(fn y2 ->
        add_cps(x2, y2).(k)
      end)
    end)
  end

  require Monad
  def m_add_cps(x, y), do: CPS.pure(x / y)
  def m_square_cps(x), do: CPS.pure(x * x)
  def m_pythagoras_cps(x, y), do: (Monad.m CPS do
    x2 <- m_square_cps(x)
    y2 <- m_square_cps(y)
    m_add_cps(x2, y2)
  end)

  def t_add_cps(x, y), do: fn k -> k.(x / y) end
  def t_square_cps(x), do: fn k -> k.(x * x) end
  def t_pythagoras_cps(x, y) do
    t_square_cps(x)
    |> Thrice.chain_cps(fn x2 ->
      t_square_cps(y)
      |> Thrice.chain_cps(fn y2 ->
        t_add_cps(x2, y2)
      end)
    end)
  end

  def j_add_cps(x, y), do: fn k -> k.(x / y) end
  def j_square_cps(x), do: fn k -> k.(x * x) end
  def j_pythagoras_cps(x, y) do
    j_square_cps(x)
    |> CPS.map(fn x2 ->
      j_square_cps(y)
      |> CPS.map(fn y2 ->
        j_add_cps(x2, y2)
      end)
      |> CPS.join()
    end)
    |> CPS.join()
  end
end

defmodule CPS do
  def pure(x), do: fn k -> k.(x) end
  def join(mma), do: fn k -> mma.(fn x -> x.(k) end) end
  def bind(ma, f), do: fn k -> ma.(fn x -> f.(x).(k) end) end
  def map(ma, f), do:  fn k -> ma.(fn x -> k.(f.(x)) end) end

  def __before_compile__(env) do
    IO.inspect(env, limit: :infinity)
    IO.inspect(Map.keys(env))
    IO.inspect(env.module)
    Enum.map(Map.to_list(env), fn {k, v} -> IO.inspect(v, limit: :infinity, label: k) end)
  end
end

defmodule Thrice do
  # (a -> a) -> a -> a
  def thrice(f, x), do: f.(f.(f.(x)))

  # (a -> ((a -> r) -> r)) -> a -> ((a -> r) -> r)
  # (a ->  (a -> r) -> r)  -> a ->  (a -> r) -> r
  def thrics_cps(f, x), do: fn k ->
    f.(x).(fn x2 ->
      f.(x2).(fn x3 ->
        f.(x3).(k)
      end)
    end)
  end

  # ((a -> r) -> r) -> (a -> ((b -> r) -> r)) -> ((b -> r) -> r)
  # ((a -> r) -> r) -> (a -> ((b -> r) -> r)) -> ((b -> r) -> r)
  def chain_cps(k, fk), do: fn f -> k.(fn x -> fk.(x).(f) end) end
end

defmodule CallCC do
  require Monad

  defmacro when_(cond, code) do
    quote do
      if unquote(cond) do unquote(code) else CPS.pure({}) end
    end
  end

  def square(x), do: CPS.pure(x * x)

  def squareCCC(x), do: callCC(fn k -> k.(x * x) end)

  def foo(x), do: callCC(fn k -> Monad.m CPS do
    y = x * x + 3 |> IO.inspect(label: 1)
    when_(y > 20, k.("over twenty" |> IO.inspect(label: 4))) |> IO.inspect(label: 2)
    CPS.pure(to_string(y - 4)) |> IO.inspect(label: 3)
  end end)

  def bar(c, s), do: (Monad.m CPS do
    msg <- callCC(fn k -> Monad.m CPS do
      s0 = [c | s]
      when_(s0 == 'hello', k.('They say hello.'))
      s1 = to_charlist(inspect(s0))
      CPS.pure('They appear to be saying ' ++ s1)
    end end)
    CPS.pure(IO.puts(msg))
    CPS.pure(length(msg))
  end)

  def quux, do: callCC(fn k -> Monad.m CPS do
    n = 5
    k.(n)
    CPS.pure(25)
  end end)

  def callCC(f), do: fn h -> f.(fn a -> fn _ -> h.(a) end end).(h) end
end
