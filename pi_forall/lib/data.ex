defmodule Data do
  def wrap_in_module(ast, name) do
    quote do
      defmodule unquote(name) do
        unquote(ast)
      end
    end
  end

  defmacro data(adt_name, do: block) do
    {adt_name, wrap_decl} =
      case adt_name do
        {:__aliases__, _, [_ | _]} -> {adt_name, &wrap_in_module(&1, adt_name)}
        {:__MODULE__, _, nil} -> {adt_name, & &1}
      end

    debug? = false

    ast =
      normalize_body(block)
      |> Enum.map(fn {name, _, args} ->
        # normalize args
        args =
          case args do
            [_ | _] = args -> args
            nil -> []
          end

        arity = length(args)
        args = Macro.generate_arguments(arity, __CALLER__.module)

        quote do
          defmacro unquote(name)(unquote_splicing(args)) do
            # {:{}, [], [unquote(name), unquote_splicing(args)]}
            {:%, [],
             [
               unquote(adt_name),
               {:%{}, [], [tag: unquote(name), fields: {:{}, [], unquote(args)}]}
             ]}
          end
        end
      end)
      |> case do
        x ->
          if debug? do
            IO.puts(Macro.to_string(x))
          end

          x
      end

    struct_decl =
      wrap_decl.(
        quote do
          @enforce_keys [:tag, :fields]
          defstruct @enforce_keys
        end
      )

    ret =
      quote do
        unquote(struct_decl)

        unquote(ast)
      end

    ret
    |> case do
      x ->
        if debug? do
          IO.puts(Macro.to_string(x))
        end

        x
    end

    ret
  end

  defmacro data(x, y) do
    IO.inspect({x, y}, label: "data(x, y)")
  end

  def normalize_body({:__block__, _meta, body}) when is_list(body) do
    body
  end

  def normalize_body(body) do
    [body]
  end
end
