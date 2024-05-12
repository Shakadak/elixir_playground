defmodule Syll do
  import Enum

  defmacro pos(x), do: {:pos, x}
  defmacro neg(x), do: {:neg, x}

  defmacro some(x), do: {:some, x}
  defmacro none, do: :none

  def option(_, f, some(x)), do: f.(x)
  def option(default, _, none()), do: default

  def lit_to_string(pos(x)), do: x
  def lit_to_string(neg(x)), do: "-" <> x

  def negate(pos(x)), do: neg(x)
  def negate(neg(x)), do: pos(x)

  def names(clauses) do
    nm = fn
      pos(x) -> x
      neg(x) -> x
    end

    clauses
    |> concat()
    |> map(nm)
    |> uniq()
    |> sort()
  end

  def unitProp(lit, clauses) do
    clauses
    |> map(&unitP(lit, &1))
    |> concat()
  end

  def unitP(lit, clause) do
    cond do
      member?(clause, lit) -> []
      member?(clause, negate(lit)) -> [List.delete(clause, negate(lit))]
      :otherwise -> [clause]
    end
  end

  def unit?([_]), do: true
  def unit?(_),   do: false

  def prop(lits, [], clauses), do: some({lits, clauses})
  def prop(lits, [unit | units], clauses) do
    if member?(lits, negate(unit)) do
      none()
    else
      newclauses = unitProp(unit, clauses)
      newlits = concat(filter(newclauses, &unit?/1))
      prop([unit | lits], units ++ newlits, clauses)
    end
  end

  def propagate(clauses) do
    prop([], concat(filter(clauses, &unit?/1)), filter(clauses, &not unit?(&1)))
  end

  defmacro kb(universal_statements, one_clause_list_per_existential_statement), do: {universal_statements, one_clause_list_per_existential_statement}

  def domain(kb(xs, yss)) do
    zs = names(xs ++ concat(yss))
    map(zs, &pos/1) ++ map(zs, &neg/1)
  end

  defmacro all(class1, class2) do quote(do: {:all, unquote(class1), unquote(class2)}) end
  defmacro no(class1, class2) do quote(do: {:no, unquote(class1), unquote(class2)}) end
  defmacro some(class1, class2) do quote(do: {:some, unquote(class1), unquote(class2)}) end
  defmacro someNot(class1, class2) do quote(do: {:someNot, unquote(class1), unquote(class2)}) end
  defmacro areAll(class1, class2) do quote(do: {:areAll, unquote(class1), unquote(class2)}) end
  defmacro areNo(class1, class2) do quote(do: {:areNo, unquote(class1), unquote(class2)}) end
  defmacro areAny(class1, class2) do quote(do: {:areAny, unquote(class1), unquote(class2)}) end
  defmacro anyNot(class1, class2) do quote(do: {:anyNot, unquote(class1), unquote(class2)}) end
  defmacro what(class1), do: {:what, class1}

  def statement_to_string(all(as, bs)),     do: "All #{lit_to_string(as)} are #{lit_to_string(bs)}."
  def statement_to_string(no(as, bs)),      do: "No #{lit_to_string(as)} are #{lit_to_string(bs)}."
  def statement_to_string(some(as, bs)),    do: "Some #{lit_to_string(as)} are #{lit_to_string(bs)}."
  def statement_to_string(someNot(as, bs)), do: "Some #{lit_to_string(as)} are not #{lit_to_string(bs)}."
  def statement_to_string(areAll(as, bs)), do: "Are all #{lit_to_string(as)} #{lit_to_string(bs)} ?"
  def statement_to_string(areNo(as, bs)),  do: "Are no #{lit_to_string(as)} #{lit_to_string(bs)} ?"
  def statement_to_string(areAny(as, bs)), do: "Are any #{lit_to_string(as)} #{lit_to_string(bs)} ?"
  def statement_to_string(anyNot(as, bs)), do: "Are any #{lit_to_string(as)} not #{lit_to_string(bs)} ?"
  def statement_to_string(what(as)), do: "What about #{lit_to_string(as)} ?"

  def is_query?(areAll(_, _)), do: true
  def is_query?(areNo(_, _)), do: true
  def is_query?(areAny(_, _)), do: true
  def is_query?(anyNot(_, _)), do: true
  def is_query?(what(_)), do: true
  def is_query?(_), do: false

  def negat(areAll(as, bs)), do: anyNot(as, bs)
  def negat(areNo(as, bs)), do: areAny(as, bs)
  def negat(areAny(as, bs)), do: areNo(as, bs)
  def negat(anyNot(as, bs)), do: areAll(as, bs)

  def subsetRel(kb) do
    classes = domain(kb)
    for x <- classes, y <- classes, propagate([[x], [negate(y)] | elem(kb, 0)]) == none() do {x, y} end
  end

  def rSection(x, r) do
    for {z, y} <- r, x == z, do: y
  end

  def supersets(class, kb), do: rSection(class, subsetRel(kb))

  def intersectRel(kb = kb(xs, yss)) do
    classes = domain(kb)
    litsList = for ys <- yss, do: option([], &elem(&1, 0), propagate(ys ++ xs))
    uniq(for x <- classes, y <- classes, lits <- litsList, member?(lits, x) and member?(lits, y) do {x, y} end)
  end

  def intersectionsets(class, kb), do: rSection(class, intersectRel(kb))

  def derive(kb, areAll(a, b)), do: member?(supersets(a, kb), b)
  def derive(kb, areNo(a, b)), do: member?(supersets(a, kb), negate(b))
  def derive(kb, areAny(a, b)), do: member?(intersectionsets(a, kb), b)
  def derive(kb, anyNot(a, b)), do: member?(intersectionsets(a, kb), negate(b))

  def update(all(a, b), kb = kb(xs, yss)) do
    na = negate(a)
    nb = negate(b)
    cond do
      member?(intersectionsets(a, kb), nb) -> none()
      member?(supersets(a, kb), b) -> some({kb, false})
      :otherwise -> some({kb([[na, b] | xs], yss), true})
    end
  end
end
