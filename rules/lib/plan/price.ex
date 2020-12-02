defmodule Plan.Price do
  require Logger

  ### API ###

  def evaluate(data) do
    consolidation_cost(Map.take(data, [:order, :plan]))
    |> preparation_cost()
    |> weight_calculation()
    |> transportation_cost()
    |> get_in([:plan, :total_price_cost])
  end

  ### RULES ###

  def consolidation_cost(data) do
    crossdocks =
      Enum.flat_map(data.plan.orchestration.orchestration, fn {prep_w_id, prep_w} ->
        Map.get(prep_w, :crossdocks, %{})
        |> Enum.map(fn {c_id, crossdock} ->
          %{
            from: c_id,
            to: prep_w_id,
            nb_items: get_items_qty(crossdock.items)
          }
        end)
      end)

    crossdocks =
      Enum.map(crossdocks, fn crossdock ->
        prep_cost_unitary = get_prep_cost(crossdock.from, "B2B")
        shuttle_cost_unitary = get_shuttle_cost(crossdock.from, crossdock.to)
        receip_cost_unitary = get_receip_cost(crossdock.to)
        Map.merge(crossdock, %{
          prep_cost_unitary: prep_cost_unitary,
          prep_cost: prep_cost_unitary * crossdock.nb_items,
          shuttle_cost_unitary: shuttle_cost_unitary,
          shuttle_cost: shuttle_cost_unitary * crossdock.nb_items,
          receip_cost_unitary: receip_cost_unitary,
          receip_cost: receip_cost_unitary * crossdock.nb_items,
        })
      end)

    total_consolidation_cost =
      Enum.sum(Enum.map(crossdocks, fn crossdock -> crossdock.prep_cost + crossdock.shuttle_cost + crossdock.receip_cost end))

    consolidation_cost_logs = %{total_consolidation_cost: total_consolidation_cost, crossdocks: crossdocks}

    plan = Map.put(data.plan, :total_price_cost, total_consolidation_cost)

    data = %{order: data.order, plan: plan, consolidation_cost_logs: consolidation_cost_logs}

    data
  end

  def preparation_cost(data) do
    channel = data.order.distributionchannelcode
    prep_warehouses =
      Enum.reduce(data.plan.orchestration.orchestration, [], fn {prep_w_id, prep_w}, acc ->
        prep_cost_unitary = get_prep_cost(prep_w_id, channel)
        nb_items = get_items_qty(prep_w.items)

        warehouse_info = %{
          warehouse_id: prep_w_id,
          nb_items: nb_items,
          distribution_channel: channel,
          prep_cost_unitary: prep_cost_unitary,
          prep_cost: prep_cost_unitary * nb_items,
        }
        acc ++ [warehouse_info]
      end)

    total_preparation_cost =
      Enum.sum(Enum.map(prep_warehouses, fn x -> x.prep_cost end))

    preparation_cost_logs = %{total_preparation_cost: total_preparation_cost, prep_warehouses: prep_warehouses}

    plan = Map.put(data.plan, :total_price_cost, data.plan.total_price_cost + total_preparation_cost)

    data = %{order: data.order, plan: plan, preparation_cost_logs: preparation_cost_logs}
    data
  end

  def weight_calculation(data) do
    orchestration = data.plan.orchestration.orchestration

    items_by_warehouse =
      Enum.reduce(orchestration, [], fn {p_w_id, p_w}, acc ->
        cumulate_items =
          Enum.reduce(p_w.crossdocks, p_w.items, fn {_, crossdock}, c_acc ->
            c_acc ++ crossdock.items
          end)
        acc ++ [{p_w_id, cumulate_items}]
      end)

    weight_calculation_logs =
      Enum.map(items_by_warehouse, fn {p_w_id, items} ->
        items_weighted =
          Enum.map(items, fn item ->
            unitary_weight = get_unitary_item_weight(item.brandcode, item.sku)
            total_weight = unitary_weight * item.quantityordered
            Map.merge(item, %{
              warehouse_id: p_w_id,
              unitary_weight: unitary_weight,
              total_weight: total_weight
            })
          end)

        total_warehouse_weight =
          Enum.sum(Enum.map(items_weighted, fn x -> x.items_weighted end))

        %{warehouse_id: p_w_id, items: items_weighted, total_warehouse_weight: total_warehouse_weight}
      end)

    data = %{order: data.order, plan: data.plan, weight_calculation_logs: weight_calculation_logs}

    data
  end

  def transportation_cost(data) do
    order_delivery_service = get_order_delivery_service(data.order)

    kilogram_transportation_price = get_kilogram_transportation_price(order_delivery_service)
    minimal_packet_price = get_minimal_packet_price(order_delivery_service)

    transportation_cost_details =
      Enum.map(data.weight_calculation_logs, fn warehouse ->
        total_weight_transportation_price = warehouse.total_warehouse_weight * kilogram_transportation_price
        %{
          warehouse_id: warehouse.warehouse_id,
          delivery_service_code: order_delivery_service,
          kilogram_transportation_price: kilogram_transportation_price,
          minimal_packet_price: minimal_packet_price,
          total_warehouse_weight: warehouse.total_warehouse_weight,
          total_weight_transportation_price: total_weight_transportation_price,
          selected_transportation_price: max(total_weight_transportation_price, minimal_packet_price)
        }
      end)

    total_transportation_cost =
      Enum.sum(Enum.map(transportation_cost_details, fn x -> x.selected_transportation_pric end))

    transportation_cost_logs = %{transportation_cost_details: transportation_cost_details, total_transportation_cost: total_transportation_cost}

    plan = Map.update!(data.plan, :total_price_cost, fn x -> x + total_transportation_cost end)

    data = %{order: data.order, plan: plan, transportation_cost_logs: transportation_cost_logs}
    data
  end

  ### INTERNALS ###

  def get_items_qty(items), do: Enum.sum(Enum.map(items, fn x -> x.quantityordered end))

  def get_prep_cost(_site, "B2B"), do: 828
  def get_prep_cost(_site, "B2C"), do: 820

  def get_shuttle_cost(_from, _to), do: 12

  def get_receip_cost(_site), do: 8765

  def get_unitary_item_weight(_brancode, _sku), do: 4

  def get_minimal_packet_price(_delivery_service_code), do: 456

  def get_kilogram_transportation_price(_delivery_service_code), do: 32

  def get_order_delivery_service(order), do: order.carrierservicecode
end
