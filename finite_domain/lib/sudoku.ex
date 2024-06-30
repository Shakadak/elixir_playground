defmodule Sudoku do
  # import FiniteDomain
  # import ComputationExpression
  # import Wrapped.StreamState


  def unlines(ls), do: Enum.join(ls, "\n")

  def displayPuzzle(pzl) do
    Enum.chunk_every(pzl, 9)
    |> Enum.map(&inspect/1)
    |> unlines()
  end

  #def printSudoku(pzl) do
  #  IO.puts(unlines(Enum.map(sudoku(pzl), &displayPuzzle/1)))
  #end

  #def sudoku(puzzle) do
  #  runFD(compute FiniteDomain do
  #    let! vars = newVars 81, 1..9
  #    do! zipWithM_ fn x, n -> whenM (n > 0), (x |> hasValue(n)) end, vars, puzzle
  #  end)
  #end
end
