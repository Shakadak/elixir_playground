defmodule Prism do
  @enforce_keys [:match, :build]
  defstruct [:match, :build]

  defmacro prism(match, build) do
    quote do
      %unquote(__MODULE__){match: unquote(match), build: unquote(build)}
    end
  end

  defmacro right(x) do
    quote do
      {:Right, unquote(x)}
    end
  end

  defmacro left(x) do
    quote do
      {:Left, unquote(x)}
    end
  end

  def the do
    match = fn
      {:Just, x} -> right(x)
      :Nothing -> left(:Nothing)
    end
    build = fn x -> {:Just, x} end

    prism(match, build)
  end

  def whole do
    proper_fraction = fn x ->
      :erlang.float_to_binary(x, [:compact, decimals: 20])
      |> String.split(".", parts: 2)
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end
    match = fn x ->
      case proper_fraction.(x) do
        {n, 0} -> right(n)
        _ -> left(x)
      end
    end
    build = &:erlang.float/1

    prism(match, build)
  end
end
