defmodule Rules.Base.Logger do
  import Monad.Logger

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
    m do
      output = %{order: order, warehouses: []}
      log {@name, output}
      fulfillement(output)
    end
  end


  @name "fulfillement"
  @coordinates {200, 200}
  def fulfillement(%{order: order}) do
    m do
      cond? = order == "0"
      log {@name, cond?}
      if cond? do
        m do
        output = %{order: order, stock: nil, leadtime: nil}
        log {@name, output}
        to_end(output)
      end
        else
        m do
          output = %{order: order, zones: generate_zones()}
          log {@name, output}
          exclusion(output)
        end
      end
    end
  end

  @name "exclusion"
  @coordinates {400, 400}
  def exclusion(%{order: order, zones: zones}) do
    m do
      cond? = order == "1"
      log {@name, cond?}
      if cond? do
        m do
        output = %{order: order, stock: nil, leadtime: nil}
        log {@name, output}
        to_end(output)
      end
        else
        m do
          output = %{order: order, zones: zones, stocks: generate_stocks()}
          log {@name, output}
          sourcing(output)
        end
      end
    end
  end

  @name "sourcing"
  @coordinates {600, 600}
  def sourcing(%{order: order, zones: zones, stocks: stocks}) do
    m do
      cond? = order == "2"
      log {@name, cond?}
      if cond? do
        m do
        output = %{order: order, stock: nil, leadtime: nil}
        log {@name, output}
        to_end(output)
      end
        else
        m do
          output = %{order: order, zones: zones, stocks: stocks, regions: generate_regions()}
          log {@name, output}
          allocation(output)
        end
      end
    end
  end

  @name "allocation"
  @coordinates {800, 600}
  def allocation(%{order: order, zones: zones, stocks: stocks, regions: regions}) do
    m do
      output = %{order: order, stock: List.first(stocks), zone: List.first(zones), region: List.first(regions)}
      log {@name, output}
      leadtime(output)
    end
  end

  @name "leadtime"
  @coordinates {1000, 600}
  def leadtime(%{order: order, stock: stock, zone: zone, region: region}) do
    m do
      output = %{order: order, stock: stock, zone: zone, region: region, leadtime: 61}
      log {@name, output}
      to_end(output)
    end
  end

  @name "to_end"
  @coordinates {1200, 200}
  def to_end(%{order: order}) do
    m do
      log {@name, order}
      pure order
    end
  end

  _ = @coordinates
end
