defmodule Naive do
  import Access

  ### DATA

  defmacro pos(x), do: {:pos, x}
  defmacro neg(x), do: {:neg, x}

  defmacro fact(object, property), do: {object, property}
  defmacro rule(antecedent, consequent), do: {antecedent, consequent}

  ### ACCESSORS

  def object, do: Access.elem(0)
  def property, do: Access.elem(1)
  def antecedent, do: Access.elem(0)
  def consequent, do: Access.elem(1)

  ### IMPL

  def negate(pos(x)), do: neg(x)
  def negate(neg(x)), do: pos(x)

  def perms(xs) do
    #_ = IO.inspect(xs, label: "perms of ")
    Comb.permutations(xs)
  end

  def forward_reasoning(rules, facts) do
    objects = Enum.map(facts, fn fact(object, _) -> object end)
    tmp_rules = for rule(p, q) <- rules, objects <- perms(objects) do
      mpps =
        Enum.group_by(p, fn fact(var, _) -> var end, fn fact(_, prop) -> prop end)

      mapping =
        Map.keys(mpps)
        |> Enum.sort()
        |> Enum.zip(objects)
        |> Map.new()

      new_p = update_in(p, [all(), object()], &Map.fetch!(mapping, &1))
      new_q = update_in(q, [all(), object()], &Map.fetch!(mapping, &1))

      rule(MapSet.new(new_p), MapSet.new(new_q))
    end
    |> Map.new()
    |> IO.inspect(label: "tmp rules")

    reach_fix_point(MapSet.new(facts), tmp_rules)
  end

  def reach_fix_point(facts, rules) do
    facts
    |> Enum.to_list()
    |> Comb.non_empty_subsequences()
    |> Enum.flat_map(fn available_facts ->
      Map.get(rules, MapSet.new(available_facts), [])
    end)
    |> case do
      additional_facts ->
        new_facts = MapSet.union(facts, MapSet.new(additional_facts))
        case MapSet.equal?(facts, new_facts) do
          true -> new_facts
          false -> reach_fix_point(new_facts, rules)
        end
    end
  end

  def example do
    facts = [
      fritz: :croaks,
      fritz: :eat_flies,
      criky: :sings,
      criky: :chirps,
    ]
    rules = %{
      [x: :croaks, x: :eat_flies] => [x: :is_a_frog],
      [x: :chirps, x: :sings] => [x: :is_a_canary],
      [x: :is_a_frog] => [x: :is_green],
      [x: :is_a_canary] => [x: :is_yellow],
    }
    [rules, facts]
  end
end
