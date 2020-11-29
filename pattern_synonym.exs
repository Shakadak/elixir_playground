# Pattern Synonyms
# by
# Matthew Pickering
# Gerg ̋o Érdi
# Simon Peyton Jones
# Richard A. Eisenberg

{:pattern, [], [{:head, [], [{:<-, [], [{:x, [], Elixir}, [{:|, [], [{:x, [], Elixir}, {:_, [], Elixir}]}]]}]}]}
{:pattern, [], [{:head, [], [{:x, [], Elixir}, {:<-, [], [[{:|, [], [{:x, [], Elixir}, {:_, [], Elixir}]}]]}]}]}


# unidirectional
# target : pattern head(x) <- [x | _]
# but doesn't work as is

lhs = {:head, [], [{:x, [], Elixir}]}
pat = [{:|, [], [{:x, [], Elixir}, {:_, [], Elixir}]}]
link = {:<-, [], [lhs, pat]}
syn = {:pattern, [], [link]}
Macro.to_string(syn) # "pattern(head(x) <- [x | _])"

# implicit bidirectional
# target : pattern just2(a, b) = just({a, b})
# currently work as is for that kind of complexity

lhs = {:just2, [], [{:a, [], Elixir}, {:b, [], Elixir}]}
pat = {:just, [], [{{:a, [], Elixir}, {:b, [], Elixir}}]}
link = {:=, [], [lhs, pat]}
syn = {:pattern, [], [link]}
Macro.to_string(syn)


# explicit bidirectional
# target : pattern polar(r, a) <- (pointPolar -> {r, a}) when polar(r, a) = polarPoint(r, a)
# but doesn't work as is
lhs = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
pat = [{:->, [], [[{:pointPolar, [], Elixir}], {{:r, [], Elixir}, {:a, [], Elixir}}]}]
lhs2 = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
expr = {:polarPoint, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
link2 = {:=, [], [lhs2, expr]}
where = {:when, [], [pat, link2]}
link = {:<-, [], [lhs, where]}
syn = {:pattern, [], [link]}
Macro.to_string(syn)

# wanted for explicit
lhs = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
pat = [{:->, [], [[{:pointPolar, [], Elixir}], {{:r, [], Elixir}, {:a, [], Elixir}}]}]
lhs2 = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
expr = {:polarPoint, [], [{:r, [], Elixir}, {:a, [], Elixir}]}
link2 = {:=, [], [lhs2, expr]}
link = {:<-, [], [lhs, pat]}
where = {:when, [], [link, link2]}
syn = {:pattern, [], [where]}
Macro.to_string(syn) # "pattern (polar(r, a) <- (pointPolar -> {r, a})) when polar(r, a) = polarPoint(r, a) "

# so parenthesis needed, we can enforce it with the macro by raising and displaying a suggestion
