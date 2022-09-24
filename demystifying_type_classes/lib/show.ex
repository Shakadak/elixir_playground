defmodule Show do
  require Class
  Class.mk :show, 1

  def print(x, dict) do
    IO.puts(show(x, dict))
  end
end

defmodule Show.Bool do
  def show(true), do: "True"
  def show(false), do: "False"
end

defmodule Show.Int do
  def show(x), do: Integer.to_string(x)
end

defmodule Show.List do
  def mk(dict) do
    %{show: &show(&1, dict)}
  end

  def show(xs, dict) do
    require Show 
    "[" <> Enum.map_join(xs, ", ", &Show.show(&1, dict)) <> "]"
  end
end
