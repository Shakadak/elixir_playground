defmodule Plan.Finder do

  ### API ###

  def find(order, opts \\ []) do
    try do
      evaluate(%{order: order, opts: opts})
    rescue
      e ->
        msg = "[ORCHESTRATION] Error happenned during orchestration of the order #{order.id} : \n #{Map.get(e, :message) || inspect e}"
        require Logger
        Logger.error("#{msg}\n" <> Exception.format(:error, e, __STACKTRACE__))
    end
  end

  ### RULES ###

  def evaluate(data) do
    data = %{order: data.order, plans: [%{}], opts: data.opts}

    data = 
      compute_orchestrations(data)
      |> eligible()

    if can_orchestrate(data) do
      data = %{order: data.order, plans: data.plans, opts: data.opts}
      costs(data)
      |> chose()
    else
      data = %{selected: %{}, costs_logs: %{}}
      data
    end
    |> Map.fetch!(:selected)
  end

  def compute_orchestrations(data) do
    plans = Enum.map(data.plans, fn plan ->
      {orchestration, unorchestrated_items} = {[], []}
      Map.put(plan, :orchestration, %{orchestration: orchestration, unorchestrated_items: unorchestrated_items})
    end)
    %{order: data.order, plans: plans, opts: data.opts}
  end

  def eligible(data) do
    decisions =
      data.plans
      |> Enum.map(fn plan ->
        decision = Plan.Elector.eligible(%{order: data.order, plan: plan})

        election = %{keep: decision}

        plan = Map.put(plan, :election, election)

        %{plan: plan, keep: decision}
      end)

    plans =
      decisions
      |> Enum.filter(fn x -> x.keep end)
      |> Enum.map(fn x -> x.plan end)

    %{
      order: data.order,
      plans: plans,
      opts: data.opts
    }
  end

  def can_orchestrate(data) do
    not Enum.empty?(data.plans)
  end

  def costs(data) do
    plans = Enum.map(data.plans, fn plan ->
      price_cost_decision          = Plan.Price.evaluate(%{order: data.order, plan: plan, opts: data.opts})
      missing_parts_cost_decision  = Plan.MissingParts.evaluate(%{order: data.order, plan: plan, opts: data.opts})

      plan
      |> Map.put(:price_cost,           price_cost_decision)
      |> Map.put(:missing_parts_cost,   missing_parts_cost_decision)
      |> Map.put(:total_cost,           price_cost_decision + missing_parts_cost_decision)
    end)

    %{
      order: data.order,
      plans: plans,
      opts: data.opts,
    }
  end

  def chose(data) do
    selected_plan = Enum.min_by(data.plans, fn plan -> plan.total_cost end)
    %{selected: selected_plan, costs_logs: %{plans: data.plans}}
  end

end
