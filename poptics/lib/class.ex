defmodule Class do
  defmacro mk(name, arity) do
    true = is_atom(name)
    args = Macro.generate_unique_arguments(arity, __MODULE__)
    quote do
      defmacro unquote(name)(unquote_splicing(args), dict) do
        args = [unquote_splicing(args)]
        name = unquote(name)
        case dict do
          {:__aliases__, _, _} ->
            quote do unquote(dict).unquote(name)(unquote_splicing(args)) end

          dict when is_atom(dict) ->
            quote do unquote(dict).unquote(name)(unquote_splicing(args)) end

          _ ->
          quote do
            case unquote(dict) do
              dict when is_atom(dict) -> dict.unquote(name)(unquote_splicing(args))
              %{unquote(name) => f} when is_function(f) -> f.(unquote_splicing(args))
            end
          end
        end
        #|> case do x -> _ = IO.puts("#{name}/#{unquote(arity)} ->\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("mk/2 ->\n#{Macro.to_string(x)}") ; x end
  end
end
