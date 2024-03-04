## # Programming
##
## * Functional Core, Imperative Shell
## * Handle data separately from control flow, as in different scope, strive for the boundary to be at least function.
## * Handling error should be handled at least in separate functions from data handling.
## * Go for historic or multivalued when possible instead of mutation.
## * Strive for idempotence in your data and data manipulation.
## * Make tracking evolving data possible on a whim
##
## * Separate multiple kinds of data:
##   - Raw data
##   - Calculated data (from raw data, can always be retrieved from it)
##   - History data (evolution of raw data, allows to restore it)
##
## * What's the lifecyle of the data ?
##
## * Minimize the depth of your data structure:
##    - deep means less confidance in applying change
##    - deep means we either need more experience with the data, or hold more inside our head.
##
##
## # Debugging
##
## * Follow the data.
## * Make dry run possible.
## * Find reproducible cases and work from them.
## * Be ready to backtrack your code, anticipate it in the way you design your solution.
## * After correction, strive to restore coherency in the data whenever and wherever possible.

defmodule Comb do
  def partition([]), do: [[]]
  def partition([x]), do: [[[x]]]
  def partition([a | as]) do
    t = partition(as)
    t1 = Enum.map(t, fn xss -> [[a] | xss] end)
    perms = Enum.concat(Enum.map(t, &permutations/1))
    perms = Enum.dedup_by(perms, &hd/1)
    t2 = Enum.map(perms, fn [xs | xss] -> [[a | xs] | xss] end)
    us = t1 ++ t2
    us = Enum.map(us, fn xss -> Enum.sort_by(xss, &length/1, &>=/2) end)
    us = Enum.sort_by(us, fn [xs | _] -> length(xs) end, &>=/2)
    Enum.sort_by(us, fn xss -> length(xss) end)
  end

  def partition_2([]), do: [[]]
  def partition_2([a | as]) do
    xsss = partition(as)
    t1 = for xss <- xsss do
      [[a] | xss]
    end
    t2 = for xss <- xsss, xs <- xss do
      [[a | xs] | (xss -- [xs])]
    end
    us = t1 ++ t2
    us = Enum.map(us, fn xss -> Enum.sort_by(xss, &length/1, &>=/2) end)
    us = Enum.sort_by(us, fn [xs | _] -> length(xs) end, &>=/2)
    Enum.sort_by(us, fn xss -> length(xss) end)
  end

  def sort_partition(us) do
    us = update_in(us, [Access.all(), Access.all()], &Enum.sort/1)
    us = update_in(us, [Access.all()], &Enum.sort/1)
    us = Enum.sort(us)
    us = Enum.map(us, fn xss -> Enum.sort_by(xss, &length(&1), &>=/2) end)
    us = Enum.sort_by(us, fn [xs | _] -> length(xs) end, &>=/2)
    Enum.sort_by(us, fn xss -> length(xss) end)
  end

  def permutations([]), do: [[]]
  def permutations(xs), do: for x <- xs, ys <- permutations(xs -- [x]), do: [x | ys]

  def subsequences(xs), do: [[] | non_empty_subsequences(xs)]
  def non_empty_subsequences([]), do: []
  def non_empty_subsequences([x | xs]), do: [[x] | List.foldr(non_empty_subsequences(xs), [], fn ys, acc -> [ys | [[x | ys] | acc]] end)]
end

defmodule SetPartition do
  def for_raw(init, pred, op, state, block) do
    if pred.(init) do
      for_raw(op.(init), pred, op, block.(init, state), block)
    else
      state
    end
  end
  def for_n(:asc, from: n, to: m) do
    Stream.unfold(n, fn
      n when n <= m -> {n, n + 1}
      _ -> nil
    end)
  end
  def for_n(:desc, from: n, to: m) do
    Stream.unfold(n, fn
      n when n >= m -> {n, n - 1}
      _ -> nil
    end)
  end

  def initialize_first(n) do
    k = Tuple.duplicate(0, n)
    m = k
    {k, m}
  end

  def initialize_last(n) do
    k = Tuple.duplicate(0, n)
    m = k
    Enum.reduce(0 .. n - 1, {k, m}, fn i, {k, m} ->
      {put_elem(k, i, i), put_elem(m, i, i)}
    end)
  end

  def next_partition({k, m}), do: next_partition(k, m)
  def next_partition(k, m) do
    n = tuple_size(k)
    Enum.reduce_while(for_n(:desc, from: n - 1, to: 1), :fail, fn i, :fail ->
      k0 = elem(k, 0)
      ki = elem(k, i)
      mi = elem(m, i)
      if ki <= elem(m, i - 1) do
        k = put_elem(k, i, ki + 1)
        m = put_elem(m, i, max(mi, elem(k, i)))
        mi = elem(m, i)
        km = Enum.reduce(for_n(:asc, from: i + 1, to: n - 1), {k, m}, fn j, {k, m} ->
          k = put_elem(k, j, k0)
          m = put_elem(m, j, mi)
          {k, m}
        end)
        {:halt, km}
      else
        {:cont, :fail}
      end
    end)
  end

  def partition_size(m), do: elem(m, tuple_size(m) - 1) - elem(m, 0) + 1

  def p_initialize_first(n, p) when p <= 0 or p > n do
    raise("p must be in 1..#{n}, received: #{p}")
  end
  def p_initialize_first(n, p) do
    k = Tuple.duplicate(0, n)
    m = k
    {k, m} = Enum.reduce(for_n(:asc, from: n - p + 1, to: n - 1), {k, m}, fn i, {k, m} ->
      {put_elem(k, i, i - (n - p)), put_elem(m, i, i - (n - p))}
    end)
    {k, m, p}
  end

  def p_initialize_last(n, p) do
    k = Tuple.duplicate(0, n)
    m = k
    {k, m} = Enum.reduce(for_n(:asc, from: 0, to: n - p), {k, m}, fn i, {k, m} ->
      {put_elem(k, i, i), put_elem(m, i, i)}
    end)
    {k, m} = Enum.reduce(for_n(:asc, from: n - p + 1, to: n - 1), {k, m}, fn i, {k, m} ->
      {put_elem(k, i, p - 1), put_elem(m, i, p - 1)}
    end)
    {k, m, p}
  end

  def p_next_partition({k, m, p}), do: p_next_partition(k, m, p)
  def p_next_partition(k, m, p) do
    n = tuple_size(k)
    Enum.reduce_while(for_n(:desc, from: n - 1, to: 1), :fail, fn i, :fail ->
      k0 = elem(k, 0)
      ki = elem(k, i)
      mi = elem(m, i)
      if ki < p - 1 and ki <= elem(m, i - 1) do
        k = put_elem(k, i, ki + 1)
        m = put_elem(m, i, max(mi, elem(k, i)))
        mi = elem(m, i)
        {k, m} = Enum.reduce(for_n(:asc, from: i + 1, to: n - (p - mi)), {k, m}, fn j, {k, m} ->
          k = put_elem(k, j, k0)
          m = put_elem(m, j, mi)
          {k, m}
        end)
        {k, m} = Enum.reduce(for_n(:asc, from: n - (p - mi) + 1, to: n - 1), {k, m}, fn j, {k, m} ->
          k = put_elem(k, j, p - (n - j))
          m = put_elem(m, j, p - (n - j))
          {k, m}
        end)
        {:halt, {k, m, p}}
      else
        {:cont, :fail}
      end
    end)
  end
end
