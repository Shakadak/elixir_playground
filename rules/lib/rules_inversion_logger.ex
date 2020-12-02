defmodule Rules.Inversion_.Logger do
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

  # (input -> Log output) -> (input -> Log bool) -> (input -> Log output) -> (input -> Log output) -> (input -> Log output)
  def split2(f, condition, true_branch, false_branch) do
    fn input ->
      m do
        input <- f.(input)
        cond? <- condition.(input)
        if cond?, do: true_branch.(input), else: false_branch.(input)
      end
    end
  end

  # (input -> Log output) -> (input -> Log output)
  def straight(f, single_branch) do
    fn input ->
      m do
        input <- f.(input)
        single_branch.(input)
      end
    end
  end

  # name -> output -> Log output
  def wrap(name, output) do
    Monad.Logger.new({[{name, output}], output})
  end

  @name "start"
  @coordinates {0, 200}
  # (input -> Log output) -> (input -> Log output)
  def start(f) do
    straight(f, fulfillement(fn input ->
      wrap(@name, %{order: input.order, warehouses: []})
    end))
  end

  @name "fulfillement"
  @coordinates {200, 200}
  # (input -> Log output) -> (input -> Log output)
  def fulfillement(f) do
    split2(f,
      fn input -> wrap(@name, input.order == "0") end,
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      exclusion(fn input -> wrap(@name, %{order: input.order, zones: generate_zones()}) end)
    )
  end

  @name "exclusion"
  @coordinates {400, 400}
  # (input -> Log output) -> (input -> Log output)
  def exclusion(f) do
    split2(f,
      fn input -> wrap(@name, input.order == "1") end,
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      sourcing(fn input -> wrap(@name, %{order: input.order, zones: input.zones, stocks: generate_stocks()}) end)
    )
  end

  @name "sourcing"
  @coordinates {600, 600}
  # (input -> Log output) -> (input -> Log output)
  def sourcing(f) do
    split2(f,
      fn input -> wrap(@name, input.order == "2") end,
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      allocation(fn input -> wrap(@name, %{order: input.order, zones: input.zones, stocks: input.stocks, regions: generate_regions()}) end)
    )
  end

  @name "allocation"
  @coordinates {800, 600}
  # (input -> Log output) -> (input -> Log output)
  def allocation(f) do
    straight(f, leadtime(fn input ->
      wrap(@name, %{order: input.order, stock: List.first(input.stocks), zone: List.first(input.zones), region: List.first(input.regions)})
    end))
  end

  @name "leadtime"
  @coordinates {1000, 600}
  # (input -> Log output) -> (input -> Log output)
  def leadtime(f) do
    straight(f, to_end(fn input ->
      wrap(@name, %{order: input.order, stock: input.stock, zone: input.zone, region: input.region, leadtime: 61})
    end))
  end

  @name "to_end"
  @coordinates {1200, 200}
  # (input -> Log output) -> (input -> Log output)
  def to_end(f) do
    straight(f, fn input -> wrap(@name, input.order) end)
  end

  _ = @coordinates
end
