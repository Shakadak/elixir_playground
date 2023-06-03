defmodule Data.Access do
  def compose(outer, inner) when is_function(outer, 3) and is_function(inner, 3) do
    fn op, data, next ->
      outer.(op, data, fn inner_data -> inner.(op, inner_data, next) end)
    end
  end

  def compose_many([access]), do: access
  def compose_many([access | tail]) do
    compose(access, compose_many(tail))
  end

  def delete_in(object, path) do
    {_, new_obj} = pop_in(object, path)
    new_obj
  end

  defmacro mk_access(do: opts) do
    actionable_opts = Enum.map(opts, fn {:->, _, [[[{lhs_name, lhs_pat}]], expr]} ->
      {lhs_name, {lhs_pat, expr}}
    end)
    {{transform_pat, transform_expr}, actionable_opts} = Keyword.pop_lazy(actionable_opts, :transform, fn -> var = Macro.var(:x, nil) ; {var, var} end)
    {{get_pat, get_expr}, actionable_opts} = Keyword.pop_lazy(actionable_opts, :on_get, fn -> raise ArgumentError, "Missing option :on_get to mk_access" end)
    {{pop_pat, pop_expr}, actionable_opts} = Keyword.pop_lazy(actionable_opts, :on_pop, fn -> raise ArgumentError, "Missing option :on_pop to mk_access" end)
    {{update_pat, update_expr}, unknown_opts} = Keyword.pop_lazy(actionable_opts, :on_update, fn -> raise ArgumentError, "Missing option :on_update to mk_access" end)
    _ = case unknown_opts do
      [] -> :ok
      _ ->
        bin = Enum.map_join(unknown_opts, ", ", fn {lhs_name, _} -> inspect(lhs_name) end)
        raise ArgumentError, "Unknown options: #{bin} for mk_access"
    end

    quote do
      fn op, data, next ->
        unquote(transform_pat) = data
        transformed = unquote(transform_expr)
        case {op, next.(transformed)} do
          {:get, unquote(get_pat)} -> unquote(get_expr)
          {:get_and_update, :pop} ->
            unquote(pop_pat) = data
            unquote(pop_expr)
          {:get_and_update, {unquote(get_pat), unquote(update_pat)}} ->
            {unquote(get_expr), unquote(update_expr)}
        end
      end
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end
end
