defmodule Json.Stream do
  def encode!(nil), do: ["null"]
  def encode!(x) when x in [false, true], do: [to_string(x)]
  def encode!(x) when is_atom(x), do: [inspect(to_string(x))]
  def encode!(x) when is_binary(x), do: [inspect(x)]
  def encode!(x) when is_number(x), do: [to_string(x)]
  def encode!(x) when is_list(x), do: Stream.concat([["["], Stream.concat(Stream.intersperse(Stream.map(x, &encode!/1), [","])), ["]"]])

  # Stream are either stream struct, or plain function/2
  def encode!(%Stream{} = x), do: Stream.concat([["["], Stream.concat(Stream.intersperse(Stream.map(x, &encode!/1), [","])), ["]"]])
  def encode!(x) when is_function(x, 2), do: Stream.concat([["["], Stream.concat(Stream.intersperse(Stream.map(x, &encode!/1), [","])), ["]"]])

  def encode!(%{__struct__: y} = x), do: raise("Structs are not handled: #{inspect(x)} (#{inspect(y)})")
  def encode!(x) when is_map(x) do
    f = fn {k, v} -> Stream.concat([[inspect(to_string(k))], [":"], encode!(v)]) end
    Stream.concat([["{"], Stream.concat(Stream.intersperse(Stream.map(x, f), [","])), ["}"]])
  end
end
