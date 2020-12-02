defmodule Plan.MissingParts do

  ### API ###

  def evaluate(data), do: missing_parts_cost(data)

  ### RULES ###

  def missing_parts_cost(data) do
    c = completeness_cost(data.order.distributionchannelcode)
    x = missing_part_tolerance(data.order.distributionchannelcode)

    nb_items_in_order = get_items_qty(data.order.items)

    nb_items_orchestrated = Enum.reduce(data.plan.orchestration.orchestration, 0, fn {_, p_w}, p_w_acc ->
      nb_crossdocks_items =
        Map.get(p_w, :crossdocks, %{})
        |> Map.values()
        |> Enum.map(fn crossdock -> get_items_qty(Map.get(crossdock, :items, [])) end)
        |> Enum.sum()

      p_w_items = Map.get(p_w, :items, [])
      p_w_acc + get_items_qty(p_w_items) + nb_crossdocks_items
    end)

    missing_parts_cost = c * max(nb_items_in_order - nb_items_orchestrated - x, 0)
    missing_parts_cost_logs = %{
      distributionchannelcode: data.order.distributionchannelcode,
      completeness_coeff_cost: c,
      nb_missing_part_tolerance: x,
      nb_items_in_order: nb_items_in_order,
      nb_items_orchestrated: nb_items_orchestrated,
      total_cost: missing_parts_cost
    }

    data = %{missing_parts_cost: missing_parts_cost, missing_parts_cost_logs: missing_parts_cost_logs}
    data.missing_parts_cost
  end

  ### INTERNALS ###

  def completeness_cost("B2C"), do: 0.8204
  def completeness_cost("B2B"), do: 0.82834

  def missing_part_tolerance("B2C"), do: 0.9879
  def missing_part_tolerance("B2B"), do: 0.74658

  def get_items_qty(items), do: Enum.sum(Enum.map(items, fn x -> x.quantityordered end))
end
