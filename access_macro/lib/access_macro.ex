defmodule Record.Access do
  @moduledoc false

  def access_helper({call, line, [arg]}) do
    get_it = {call, line, [Macro.var(:data, nil), arg]}
    update_it = {call, line, [Macro.var(:data, nil), [{arg, Macro.var(:update, nil)}]]}
    # We can't generate records at runtime, so we need to :
    defaults = {call, line, []} # hardcode a new one,
    default_for_arg = {call, line, [defaults, arg]} # get the default value from it,
    # and then use the default to replace the current value as records should keep their size.
    pop_it = {call, line, [Macro.var(:data, nil), [{arg, default_for_arg}]]}
    quote do
      fn
        :get, var!(data), next ->
          next.(unquote(get_it))

        :get_and_update, var!(data), next ->
          value = unquote(get_it)

          case next.(value) do
            {get, var!(update)} -> {get, unquote(update_it)}
            :pop -> {value, unquote(pop_it)}
          end
      end
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end

  defmacro to_access(xs) when is_list(xs) do Enum.map(xs, fn x -> access_helper(x) end) end
  defmacro to_access({_, _, _} = x) do access_helper(x) end
end
