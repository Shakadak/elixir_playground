defmodule Rules.Inversion_.Decorated do
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

  # () -> {deco, computation}
  def build do
    start(&Monad.Logger.pure/1)
  end

  def tree_to_graph(tree) do
    parent = [{Map.take(tree, [:name, :coordinates]), Enum.map(tree.children, fn subtree -> Map.take(subtree, [:name, :coordinates]) end)}]
    children = Enum.flat_map(tree.children, &tree_to_graph/1)
    parent ++ children
  end

  def skiny_graph(graph) do
    Enum.map(graph, fn {node, links} -> {node.name, Enum.map(links, fn link -> link.name end)} end)
    |> Enum.uniq()
    |> Enum.group_by(fn {node, _} -> node end, fn {_, links} -> links end)
    |> Map.new(fn {node, linkss} -> {node, Enum.uniq(Enum.concat(linkss))} end)
  end

  def run(input, computation) do
    computation.(input)
  end

  # (input -> Log output) -> {deco, (input -> Log bool)} -> {deco, input -> Log output} -> {deco, input -> Log output} -> {deco, input -> Log output}
  def split2(deco, f, condition, true_branch, false_branch) do
    {deco_c, condition} = condition
    {deco_t, true_branch} = true_branch
    {deco_f, false_branch} = false_branch

    deco = Map.update!(deco, :children, fn xs -> xs ++ [deco_c, deco_t, deco_f] end)

    computation = fn input ->
      m do
        input <- f.(input)
        cond? <- condition.(input)
        if cond?, do: true_branch.(input), else: false_branch.(input)
      end
    end

    {deco, computation}
  end

  # deco -> (input -> Log output) -> [{{deco, (input -> Log output) -> input -> Log (Maybe output)}, {deco, input -> Log output}}] -> {deco, input Log output}
  #def split_many(deco, f, branches) do
  #  {decos, computations} =
  #    Enum.unzip(Enum.map(branches, fn {{a, x}, {b, y}} -> {{a, b}, {x, y}} end))

  #  {internal_decos, children_decos} = Enum.unzip(decos)

  #  deco = Map.update!(deco, :internals, fn xs -> [xs] ++ internal_decos end)
  #  deco = Map.update!(deco, :children, fn xs -> [xs] ++ children_decos end)

  #  computation = fn input ->
  #    m do
  #      input <- f.(input)
  #      Enum.reduce_while(computations
  #end

  # (input -> Log output) -> {deco, input -> Log output} -> {deco, input -> Log output}
  def straight(deco, f, single_branch) do
    {deco_n, single_branch} = single_branch

    deco = Map.update!(deco, :children, fn xs -> xs ++ [deco_n] end)

    computation = fn input ->
      m do
        input <- f.(input)
        single_branch.(input)
      end
    end

    {deco, computation}
  end

  # name -> output -> Log output
  def wrap(name, output) do
    Monad.Logger.new({[{name, output}], output})
  end

  @name "start"
  @coordinates {0, 200}
  # (input -> Log output) -> {deco, input -> Log output}
  def start(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    straight(deco, f, fulfillement(fn input ->
      wrap(@name, %{order: input.order, warehouses: []})
    end))
  end

  @name "fulfillement"
  @coordinates {200, 200}
  # (input -> Log output) -> {deco, input -> Log output}
  def fulfillement(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    split2(deco, f,
      {deco, fn input -> wrap(@name, input.order == "0") end},
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      exclusion(fn input -> wrap(@name, %{order: input.order, zones: generate_zones()}) end)
    )
  end

  @name "exclusion"
  @coordinates {400, 400}
  # (input -> Log output) -> {deco, input -> Log output}
  def exclusion(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    split2(deco, f,
      {deco, fn input -> wrap(@name, input.order == "1") end},
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      sourcing(fn input -> wrap(@name, %{order: input.order, zones: input.zones, stocks: generate_stocks()}) end)
    )
  end

  @name "sourcing"
  @coordinates {600, 600}
  # (input -> Log output) -> {deco, input -> Log output}
  def sourcing(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    split2(deco, f,
      {deco, fn input -> wrap(@name, input.order == "2") end},
      to_end(fn input -> wrap(@name, %{order: input.order, stock: nil, leadtime: nil}) end),
      allocation(fn input -> wrap(@name, %{order: input.order, zones: input.zones, stocks: input.stocks, regions: generate_regions()}) end)
    )
  end

  @name "allocation"
  @coordinates {800, 600}
  # (input -> Log output) -> {deco, input -> Log output}
  def allocation(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    straight(deco, f, leadtime(fn input ->
      wrap(@name, %{order: input.order, stock: List.first(input.stocks), zone: List.first(input.zones), region: List.first(input.regions)})
    end))
  end

  @name "leadtime"
  @coordinates {1000, 600}
  # (input -> Log output) -> {deco, input -> Log output}
  def leadtime(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    straight(deco, f, to_end(fn input ->
      wrap(@name, %{order: input.order, stock: input.stock, zone: input.zone, region: input.region, leadtime: 61})
    end))
  end

  @name "to_end"
  @coordinates {1200, 200}
  # (input -> Log output) -> {deco, input -> Log output}
  def to_end(f) do
    deco = %{name: @name, coordinates: @coordinates, children: []}
    deco_stop = %{name: "stop", coordinates: {1200, 400}, children: []}
    straight(deco, f, {deco_stop, fn input -> wrap(@name, input.order) end})
  end
end
