defmodule Plan.Elector do
  require Logger

  ### API ###

  def eligible(data) do
    if is_active?(data.plan) do
      can_be_shipped_logs = get_shipped_infos(data.order, data.plan)

      not Enum.empty?(can_be_shipped_logs) and Enum.all?(can_be_shipped_logs) and can_be_served?(data.plan.orchestration.orchestration)
    else
        false
    end
  end

  ### INTERNALS ###

  def is_active?(plan), do: plan.is_active

  def get_shipped_infos(%{carrierservicecode: carrier_service_code} = _order, %{prep_warehouses: prep_warehouses, orchestration: %{orchestration: orchestration}} = _plan) do
    orchestration
    # get transport services asked in the plan only for the warehouse implied in orchestration
    |> Enum.map(fn {warehouse_id, _} ->
      Enum.find_value(prep_warehouses, fn prep_warehouse ->
        if prep_warehouse.id == warehouse_id, do: {prep_warehouse.id, prep_warehouse.transports}
      end)
    end)
    |> Enum.map(fn {warehouse_id, plan_transports} ->
      is_include? = fn (list, value) ->
        Enum.find_value(list, false, fn
          ^value -> true
          _ -> false
        end)
      end
      is_include_in_plan = is_include?.(plan_transports, carrier_service_code)

      warehouse_transports = []
      is_include_in_deliverydays = is_include?.(warehouse_transports, carrier_service_code)

      %{warehouse_id: warehouse_id, order_carrier_service_code: carrier_service_code, plan_transports: plan_transports, warehouse_transports: warehouse_transports, can_be_shipped: is_include_in_plan and is_include_in_deliverydays}
    end)
  end

  def can_be_served?(orchestration), do: orchestration != %{}
end
