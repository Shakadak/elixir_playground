defmodule Example.Cli do
  def test_easiest do 
    [
      4, 6, 7, 9, 2, 1, 3, 5, 8,
      8, 9, 5, 4, 7, 3, 2, 6, 1,
      2, 3, 1, 8, 6, 5, 7, 4, 9,
      5, 1, 3, 6, 9, 8, 4, 2, 7,
      9, 2, 8, 7, 0, 4, 6, 1, 3,
      7, 4, 6, 1, 3, 2, 9, 8, 5,
      3, 5, 4, 2, 8, 7, 1, 9, 6,
      1, 8, 9, 3, 4, 6, 5, 7, 2,
      6, 7, 2, 5, 1, 9, 8, 3, 4,
    ]
  end

  def test_easy do
    [
      300095670,
      020400815,
      751062000,
      018350006,
      075600490,
      900704108,
      042073001,
      507010084,
      100208530,
    ] |> Enum.map(fn n ->
      String.pad_leading(Integer.to_string(n), 9, "0")
      |> String.split("", trim: true)
      |> Enum.map(&String.to_integer/1)
    end)
    |> Enum.concat()
  end

  # http://lipas.uwasa.fi/~timan/sudoku/

  # s01a.txt
  def test_kinda_easy do
    """
    0 4 0 0 0 0 1 7 9 
    0 0 2 0 0 8 0 5 4 
    0 0 6 0 0 5 0 0 8 
    0 8 0 0 7 0 9 1 0 
    0 5 0 0 9 0 0 3 0 
    0 1 9 0 6 0 0 4 0 
    3 0 0 4 0 0 7 0 0 
    5 7 0 1 0 0 2 0 0 
    9 2 8 0 0 0 0 6 0 
    """
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  # s02a.txt
  def test_kinda_mid do
    """
    2 0 6 0 0 0 0 4 9 
    0 3 7 0 0 9 0 0 0 
    1 0 0 7 0 0 0 0 6 
    0 0 0 5 8 0 9 0 0 
    7 0 5 0 0 0 8 0 4 
    0 0 9 0 6 2 0 0 0 
    9 0 0 0 0 4 0 0 1 
    0 0 0 3 0 0 4 9 0 
    4 1 0 0 0 0 2 0 8 
    """
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end



  # s04a.txt
  def test_kinda_hard do
    """
    0 5 0 0 9 0 0 0 0 
    0 0 4 8 0 0 0 0 9 
    0 0 0 1 0 7 2 8 0 
    5 6 0 0 0 0 1 3 7 
    0 0 0 0 0 0 0 0 0 
    1 7 3 0 0 0 0 4 2 
    0 2 1 5 0 8 0 0 0 
    6 0 0 0 0 3 8 0 0 
    0 0 0 0 1 0 0 6 0 
    """
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  def test_dm_overton do
    [
      0, 0, 0, 0, 8, 0, 0, 0, 0,
      0, 0, 0, 1, 0, 6, 5, 0, 7,
      4, 0, 2, 7, 0, 0, 0, 0, 0,
      0, 8, 0, 3, 0, 0, 1, 0, 0,
      0, 0, 3, 0, 0, 0, 8, 0, 0,
      0, 0, 5, 0, 0, 9, 0, 7, 0,
      0, 5, 0, 0, 0, 8, 0, 0, 6,
      3, 0, 1, 2, 0, 4, 0, 0, 0,
      0, 0, 6, 0, 1, 0, 0, 0, 0
    ]
  end


  def main(_args) do
    Sudoku.printSudoku test_kinda_mid()
  end
end
