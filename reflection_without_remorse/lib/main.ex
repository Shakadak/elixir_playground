defmodule Main do

  ### Slow-downs and speed ups of list concatenations

  def sample do
    {Node, ~c"Root",
      {Arr, [
        {Node, ~c"Ch1", {A, 1}},
        {Node, ~c"Ch2", {A, 2}}
      ]}
    }
  end

  def makej(0), do: {A, 1}
  def makej(d), do: {Node, ~c"node-name", makej(d - 1)}

  def showj({A, x}), do: to_charlist(inspect x)
  def showj({Node, t, j}), do: ~c"{" ++ t ++ ~c" " ++ showj(j) ++ ~c"}"
  # Don't handle Arr yet

  def fromDiff(x), do: x.([])
  def toDiff(l), do: fn t -> l ++ t end

  def l <<< r, do: fn x -> l.(r.(x)) end

  def showjCPS(j), do: fromDiff(go_showjCPS(j))

  def go_showjCPS({A, x}), do: toDiff(to_charlist(inspect(x)))
  def go_showjCPS({Node, t, j}) do
    toDiff(~c"{") <<< toDiff(t) <<< toDiff(~c" ") <<< go_showjCPS(j) <<< toDiff(~c"}")
  end
  # Don't handle arrays yet

  def showLst([]), do: ~c"[]"
  def showLst([h | t]) do
    [p | s] = showLst(t)
    [p | to_charlist(inspect(h)) ++ (if s == ~c"]" do s else ~c"," ++ s end)]
  end

  def showjCPS1(j), do: fromDiff(go_showjCPS1(j))
  # This part is as before
  def go_showjCPS1({A, x}), do: toDiff(to_charlist(inspect(x)))
  def go_showjCPS1({Node, t, j}) do
    toDiff(~c"{") <<< toDiff(t) <<< toDiff(~c" ") <<< go_showjCPS1(j) <<< toDiff(~c"}")
  end
  # The new part: showing arrays of nodes
  def go_showjCPS1({Arr, []}), do: toDiff(~c"[]")
  def go_showjCPS1({Arr, [h | t]}) do
    [p | s] = fromDiff(go_showjCPS1({Arr, t}))
    (&[p | &1]) <<< go_showjCPS1(h) <<< toDiff(if s == ~c"]" do s else ~c"," ++ s end)
  end

  alias Hallux.Seq

  def showjSeq(j), do: Enum.to_list(go_showjSeq(j))

  def char(c), do: Seq.new([c])
  def str(l), do: Seq.new(l)

  def go_showjSeq({A, x}), do: str(to_charlist(inspect(x)))
  def go_showjSeq({Node, t, j}) do
    str(~c"{")
    |> Seq.concat(str(t))
    |> Seq.concat(str(~c" "))
    |> Seq.concat(go_showjSeq(j))
    |> Seq.concat(str(~c"}"))
  end

  def go_showjSeq({Arr, []}), do: str(~c"[]")
  def go_showjSeq({Arr, [h | t]}) do
    {p, s} = Seq.view_l(go_showjSeq({Arr, t}))
    char(p)
    |> Seq.concat(go_showjSeq(h))
    |> Seq.concat(case Seq.view_l(s) do
      {?], _} -> s
      _ -> char(?,) |> Seq.concat(s)
    end)
  end

  ### Slow-downs and speed-ups of monad concatenations

  def get, do: {Get, &return/1}

  def return(x), do: {Pure, x}

  def bind({Pure, x}, k), do: k.(x)
  def bind({Get, f}, k), do: {Get, f >>> k}

  def f >>> g, do: fn x -> x |> f.() |> bind(g) end

  def addGet(x), do: get() |> bind(fn i -> return(i + x) end)
  # glibly : def addGet(x), do: (& &1 + x) <*> get()

  def addN(n), do: (Enum.reduce(List.duplicate(&addGet/1, n), &return/1, & &2 >>> &1)).(0)

  def feedAll({Pure, a}, _), do: {Just, a}
  def feedAll(_, []), do: Nothing
  def feedAll({Get, f}, [h | t]), do: feedAll(f.(h), t)

  def zreturn(x), do: {ZPure, x}

  def zbind({ZPure, x}, k), do: k.(x)
  def zbind({ZGet, f}, k), do: {ZGet, f |> Seq.snoc(k)} # New

  def getZ, do: {ZGet, Seq.new()}

  def addGetZ(x), do: liftM(& &1 + x, getZ())

  def liftM(f, m), do: m |> zbind(fn x -> zreturn(f.(x)) end)

  def addNZ(n), do: Enum.reduce(List.duplicate(&addGetZ/1, n), &zreturn/1, & &2 ~>> &1).(0)

  def f ~>> g, do: fn x -> x |> f.() |> zbind(g) end

  def feedAllZ({ZPure, a}, _), do: {Just, a}
  def feedAllZ(_, []), do: Nothing
  def feedAllZ({ZGet, f}, [h | t]), do: feedAllZ(appZ(f, h), t)

  def appZ(q, x) do
    case Seq.view_l(q) do
      nil -> zreturn(x)
      {h, t} -> case h.(x) do
        {ZPure, x} -> appZ(t, x)
        {ZGet, f} -> {ZGet, Seq.concat(f, t)}
      end
    end
  end
end
