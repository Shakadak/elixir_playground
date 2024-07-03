defmodule Sudoku do
  import FiniteDomain
  import ComputationExpression
  import Wrapped.StreamState


  def unlines(ls), do: Enum.join(ls, "\n")

  def displayPuzzle(pzl) do
    Enum.chunk_every(pzl, 9)
    |> Enum.map(&inspect(&1, charlists: :as_lists))
    |> unlines()
    |> Kernel.<>("\n\n")
  end

  def printSudoku(pzl) do
    IO.puts(unlines(Enum.map(sudoku(pzl), &displayPuzzle/1)))
  end

  def zipWithM_(_, [], _), do: pure {}
  def zipWithM_(_, _, []), do: pure {}
  def zipWithM_(f, [x | xs], [y | ys]) do
    compute FiniteDomain do
      let! _ = f.(x, y)
      pure! zipWithM_(f, xs, ys)
    end
  end

  def print(str), do: (IO.puts(str) ; {})

  def sudoku(puzzle) do
    runFD(compute FiniteDomain do
      let! vars = newVars 81, 1..9
      do! zipWithM_ fn x, n -> whenM (n > 0), (x |> hasValue(n)) end, vars, puzzle
      # let! state = get()
      # let _ = IO.inspect(state.varMap |> Enum.sort() |> Enum.map(fn {x, s} -> {x, s.values} end), label: "sudoku initial state", limit: :infinity)
      do! mapM_ (rows vars), &allDifferent/1
      do! mapM_ (columns vars), &allDifferent/1
      do! mapM_ (boxes vars), &allDifferent/1
      pure! labelling vars
    end)
  end

  def rows(xs), do: Enum.chunk_every(xs, 9)
  def columns(xs), do: transpose (rows xs)
  def boxes(xs) do
    xs
    |> Enum.chunk_every(3)
    |> Enum.chunk_every(3)
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.concat(transpose(&1)))
    |> Enum.concat()
  end
  def transpose(xs), do: Enum.zip_with(xs, & &1)
end
