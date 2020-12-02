defmodule Rules.Cps do
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

  require Monad

  @name "start"
  @coordinates {0, 200}
  def start(input) do
    Monad.m CPS do
      fulfillement(%{order: input.order, warehouses: []} |> IO.inspect(label: @name))
    end
  end


  @name "fulfillement"
  @coordinates {200, 200}
  def fulfillement(input) do
    Monad.m CPS do
      if input.order == "0" |> IO.inspect(label: @name) do
        to_end(%{order: input.order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
      else
        exclusion(%{order: input.order, zones: generate_zones()} |> IO.inspect(label: @name))
      end
    end
  end

  @name "exclusion"
  @coordinates {400, 400}
  def exclusion(input) do
    Monad.m CPS do
    if input.order == "1" |> IO.inspect(label: @name) do
      to_end(%{order: input.order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
    else
      sourcing(%{order: input.order, zones: input.zones, stocks: generate_stocks()} |> IO.inspect(label: @name))
    end
    end
  end

  @name "sourcing"
  @coordinates {600, 600}
  def sourcing(input) do
    Monad.m CPS do
    if input.order == "2" |> IO.inspect(label: @name) do
      to_end(%{order: input.order, stock: nil, leadtime: nil} |> IO.inspect(label: @name))
    else
      allocation(%{order: input.order, zones: input.zones, stocks: input.stocks, regions: generate_regions()} |> IO.inspect(label: @name))
    end
    end
  end

  @name "allocation"
  @coordinates {800, 600}
  def allocation(input) do
    Monad.m CPS do
    leadtime(%{order: input.order, stock: List.first(input.stocks), zone: List.first(input.zones), region: List.first(input.regions)} |> IO.inspect(label: @name))
    end
  end

  @name "leadtime"
  @coordinates {1000, 600}
  def leadtime(input) do
    Monad.m CPS do
    to_end(%{order: input.order, stock: input.stock, zone: input.zone, region: input.region, leadtime: 61} |> IO.inspect(label: @name)) #61 hours
    end
  end

  @name "to_end"
  @coordinates {1200, 200}
  def to_end(input) do
    Monad.m CPS do
    CPS.pure(input.order |> IO.inspect(label: @name))
    end
  end

  _ = @coordinates
end
