defmodule Struct do
  defmacro mk({name, _meta, params}) when is_list(params) or is_nil(params) do
    # IO.inspect(params, label: "#{name} ast params")
    params = case params do
      nil -> []
      [params] when is_list(params) -> params
    end

    {params, types} = Enum.unzip(params)
    params = Enum.map(params, &Macro.unique_var(&1, __MODULE__))
    wild_params = List.duplicate(Macro.var(:_, __MODULE__), length(params))

    quote do
      @type unquote(Macro.var(name, __MODULE__)) :: {unquote(name), unquote_splicing(types)}
      defmacro unquote(name)(unquote_splicing(params)) do
        name = unquote(name)
        params = unquote(params)
        quote do
          {unquote(name), unquote_splicing(params)}
        end
        # |> IO.inspect(label: "#{unquote(name)} macro result")
        # |> tap(&IO.puts(Macro.to_string(&1)))
      end

      def unquote(:"#{name}?")({unquote(name), unquote_splicing(wild_params)}), do: true
      def unquote(:"#{name}?")(_), do: false
    end
    # |> IO.inspect(label: "#{name} macro def")
    # |> tap(&IO.puts(Macro.to_string(&1)))
  end
end
