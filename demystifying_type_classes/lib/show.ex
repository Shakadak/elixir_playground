defmodule Show do
  require Class
  Class.mk :show, 1

  def print(x, dict) do
    IO.puts(show(x, dict))
  end
end

defmodule Show.Bool do
  def show, do: fn
    (true) -> "True"
    (false) -> "False"
  end
end

defmodule Show.Int do
  def show, do: fn (x) -> Integer.to_string(x) end
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
