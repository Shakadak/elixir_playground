defmodule FDState do
  @enforce_keys [:varSupply, :varMap]
  defstruct @enforce_keys
end

defmodule VarInfo do
  @enforce_keys [:delayedConstraints, :values]
  defstruct @enforce_keys
end

defmodule FD do
  @enforce_keys [:unFD]
  defstruct @enforce_keys
end

defmodule FiniteDomain do
  require ComputationExpression, as: CE

  import Wrapped.StreamState

  ### COMPUTATION EXPRESSION -------------------------------------------------------------

  def _Pure(x), do: Wrapped.StreamState.pure(x)

  def _Bind(m, f), do: Wrapped.StreamState.bind(m, f)

  def _PureFrom(m), do: m

  def _Zero, do: Wrapped.StreamState.pure({})

  def _Combine(l, rk), do: Wrapped.StreamState.bind(l, fn {} -> rk.() end)

  def _Delay(k), do: k

  def _Run(k), do: k.()

  ### ------------------------------------------------------------------------------------

  def runFD fd do
    evalStateT fd, initState()
  end

  def initState do
    %FDState{varSupply: 0, varMap: %{}}
  end

  def newVar domain do
    CE.compute __MODULE__ do
      let! v = nextVar()
      do! v |> (isOneOf domain)
      pure v
    end
  end

  def nextVar do
    CE.compute __MODULE__ do
      let! s = get()
      let v = s.varSupply
      do! put %FDState{s | varSupply: v + 1}
      pure v
    end
  end

  def isOneOf(x, %Range{} = domain), do: (isOneOf x, (Enum.to_list domain))
  def isOneOf(x, domain) when (is_list domain) do
    modify fn s ->
      vm = s.varMap
      vi = %VarInfo{
        delayedConstraints: (pure {}),
        values: (MapSet.new domain),
      }
      %FDState{s | varMap: Map.put(vm, x, vi)}
    end
  end

  def newVars n, domain do
    replicateM n, (newVar domain)
  end

  # Lookup the current domain of a variable
  def lookup x do
    CE.compute __MODULE__ do
      let! s = get()
      pure (Map.fetch!(s.varMap, x).values)
    end
  end

  # update the domain of a variable and fire all delayed constraints
  # associated with that variable
  def update x, i do
    CE.compute __MODULE__ do
      let! s = get()
      let vm = s.varMap
      let vi = Map.fetch! vm, x
      do! put %FDState{s | varMap: Map.put(vm, x, %VarInfo{vi | values: i})}
      pure! vi.delayedConstraints
    end
  end

  # add a new constraint for a variable to the constraint store
  def addConstraint x, constraints do
    CE.compute __MODULE__ do
      let! s = get()
      let vm = s.varMap
      let vi = Map.fetch! vm, x
      let cs = vi.delayedConstraints
      pure! (put %FDState{s | varMap: Map.put(vm, x, %VarInfo{vi | delayedConstraints: CE.compute __MODULE__ do do! cs ; pure! constraints end})})
    end
  end

  # Useful helper function for adding binary constraints between FDVars
  def addBinaryConstraint f, x, y do
    CE.compute __MODULE__ do
      let constraint = f.(x, y)
      do! constraint
      do! addConstraint x, constraint
      do! addConstraint y, constraint
    end
  end

  def hasValue var, val do
    CE.compute __MODULE__ do
      let! vals = lookup var
      do! guard MapSet.member?(vals, val)
      let i = MapSet.new([val])
      if i != vals do do! update var, i end
    end
  end

  def same x, y do
    addBinaryConstraint fn x, y ->
      CE.compute __MODULE__ do
        do! pure {}
        let! xv = lookup x
        let! yv = lookup y
        let i = MapSet.intersection xv, yv
        do! guard not Enum.empty? i
        do! whenM i != xv, (update x, i)
        do! whenM i != yv, (update y, i)
      end
    end, x, y
  end

  def different x, y do
    addBinaryConstraint fn x, y ->
      CE.compute __MODULE__ do
        let! xv = lookup x
        let! yv = lookup y
        do! guard (MapSet.size(xv) > 1 or MapSet.size(yv) > 1 or xv != yv)
      end
    end, x, y
  end

  def allDifferent [x | xs] do
    CE.compute __MODULE__ do
      do! mapM_ xs, &(different x, &1)
      pure! allDifferent xs
    end
  end

  def allDifferent [] do pure {} end

  def lessThan(l, r) do
    addBinaryConstraint fn x, y ->
      CE.compute __MODULE__ do
        let! xv = lookup x
        let! yv = lookup y
        let xmin = Enum.min xv
        let ymax = Enum.max yv
        let xv2 = MapSet.filter xv, & &1 < ymax
        let yv2 = MapSet.filter yv, & &1 > xmin
        do! guard not Enum.empty?(xv2)
        do! guard not Enum.empty?(yv2)
        do! whenM xv != xv2, (update x, xv2)
        do! whenM yv != yv2, (update y, yv2)
      end
    end, l, r
  end

  def labelling xs do
    mapM xs, fn var ->
      CE.compute __MODULE__ do
        let! vals = lookup var
        let! val = lift MapSet.to_list(vals)
        do! var |> (hasValue val)
        pure val
      end
    end
  end

  defdelegate mplus(l, r), to: Wrapped.StreamState
end
