defmodule TypeDeclaration do
  import Circe

  defmacro data(~m/#{name}(#{...params})/, do: block) do
    _ = IO.inspect(name, label: "data:name")
    _ = IO.inspect(params, label: "data:params")
    _ = IO.inspect(block, label: "data:block")
    nil
  end

  defmacro newtype(~m/#{name}(#{...params})/, do: type) do
    _ = IO.inspect(name, label: "newtype:name")
    _ = IO.inspect(params, label: "newtype:params")
    _ = IO.inspect(type, label: "newtype:type")
    nil
  end

  defmacro type_syn(~m/#{name}(#{...params})/, type) do
    _ = IO.inspect(name, label: "type_syn:name")
    _ = IO.inspect(params, label: "type_syn:params")
    _ = IO.inspect(type, label: "type_syn:type")
    nil
  end
end
