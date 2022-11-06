defmodule TypedAttempt do
  import Circe

  defmacro det(x, y) do
    IO.inspect(__CALLER__.module)
    debug? = true
    :maps.map(fn k, v -> IO.inspect(v, label: k) end, __CALLER__)
    #IO.inspect(Module.attributes_in(__CALLER__.module))
    _ = Module.delete_attribute(__CALLER__.module, :debug)
    if debug? do
      IO.inspect(x)
      IO.inspect(y)
    end

    z = [x, y]
    quote do
      def unquote_splicing(z)
    end
    |> case do x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end
        ; x
    end
  end

  defmacro typ(~m/#{function} :: #{type}/) do
    _ = IO.inspect(function, label: :function)
    _ = IO.inspect(type, label: :type)
    nil
  end

  defmacro foreign(~m/#{module}.#{function} :: #{type}/) do
    aliases = Map.new(__CALLER__.aliases)
    _ = IO.inspect(module)
    module = case module do
      {:__aliases__, meta, xs} ->
        Keyword.fetch(meta, :alias)
        |> case do
          {:ok, module} when is_atom(module) -> module
          # {:ok, false} -> Module.concat(xs)
          :error -> Module.concat(xs)
        end

      other ->
        %{^other => module} = aliases
        module
    end
    # Keep in mind to maybe handle aliases ?
    _ = IO.inspect(module, label: :module)
    _ = IO.inspect(function, label: :function)
    _ = IO.inspect(type, label: :type)
    _ = Module.register_attribute(module, :types, persist: true)
    types = Module.get_attribute(module, :types, %{})
    types = Map.update(types, function, type, fn type1 ->
      raise("Type for #{inspect(module)}.#{function} already exist : #{Macro.to_string(type1)} (would be replaced with : #{Macro.to_string(type)}")
    end)
    _ = Module.put_attribute(module, :types, types)
    nil
  end
end
