defmodule Rules.Graph.Brut do

  def rules_result, do: Enum.random(["", "12"])

  def generate_zones do
    [
      %{id: "123", name: "Cartier EU"},
      %{id: "11", name: "Cartier Asia"},
      %{id: "41", name: "Cartier NA"},
    ]
  end

  def generate_stocks do
    [
      %{location: "PW", location_type: "supply", country: "FR",  quantity: 999},
      %{location: "RW", location_type: "store", country: "FR",   quantity: 999},
      %{location: "GD", location_type: "store", country: "UK",   quantity: 999},
      %{location: "GCD", location_type: "supply", country: "UK", quantity: 999},
    ]
  end

  def generate_regions do
    [
      %{location: "PW", location_type: "supply", country: "FR", quantity: 999, rank: 1},
      %{location: "RW", location_type: "store", country: "FR",  quantity: 999, rank: 2},
    ]
  end

  @name "start"
  @coordinates {0, 200}
  def start(%{order: order}) do
    fulfillement(%{order: order, warehouses: []} |> IO.inspect(label: @name))
  end


  @name "fulfillement"
  @coordinates {200, 200}
  def fulfillement(%{order: order}) do
    if (order == "0")  |> IO.inspect(label: @name) do
      to_end(%{order: order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
    else
      exclusion(%{order: order, zones: generate_zones()} |> IO.inspect(label: @name))
    end
  end

  @name "exclusion"
  @coordinates {400, 400}
  def exclusion(%{order: order, zones: zones}) do
    if (order == "1")  |> IO.inspect(label: @name) do
      to_end(%{order: order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
    else
      sourcing(%{order: order, zones: zones, stocks: generate_stocks()} |> IO.inspect(label: @name))
    end
  end

  @name "sourcing"
  @coordinates {600, 600}
  def sourcing(%{order: order, zones: zones, stocks: stocks}) do
    if (order == "2")  |> IO.inspect(label: @name) do
      to_end(%{order: order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
    else
      allocation(%{order: order, zones: zones, stocks: stocks, regions: generate_regions()} |> IO.inspect(label: @name))
    end
  end

  @name "allocation"
  @coordinates {800, 600}
  def allocation(%{order: order, zones: zones, stocks: stocks, regions: regions}) do
    leadtime(%{order: order, stock: List.first(stocks), zone: List.first(zones), region: List.first(regions)} |> IO.inspect(label: @name))
  end

  @name "leadtime"
  @coordinates {1000, 600}
  def leadtime(%{order: order, stock: stock, zone: zone, region: region}) do
    to_end(%{order: order, stock: stock, zone: zone, region: region, leadtime: 61} |> IO.inspect(label: @name)) #61 hours
  end

  @name "to_end"
  @coordinates {1200, 200}
  def to_end(%{order: order}) do
    order |> IO.inspect(label: @name)
  end

  _ = @coordinates
end
