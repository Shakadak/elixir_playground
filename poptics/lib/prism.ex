defmodule Prism do
  import Type

  record prism(a, b, s, t) = prism %{match: (s -> either(t, a)), build: (b -> t)}

  import Either

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
