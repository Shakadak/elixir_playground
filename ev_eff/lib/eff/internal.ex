defmodule Eff.Internal do
  def wrap(ast, module, module, _marked) do
    ast
  end

  def wrap(ast, _calling, module, marked) do
    Macro.postwalk(ast, fn
      {op, _, _} = ast ->
        if op in marked do
          quote do unquote(module).unquote(ast) end
        else
          ast
        end
      ast -> ast
    end)
  end

  defguard is_var(v) when is_tuple(v) and tuple_size(v) == 3 and is_atom(elem(v, 0)) and is_atom(elem(v, 2))

  def convert_fn(var, ast) do
    #remove_fn(var, ast)
    to_case(var, ast)
    #{:fn, ast}
  end

  def to_case(replacing_var, ast) do
    case ast do
      {:fn, meta, clauses} ->
        #_ = IO.puts("fn detected in file #{__CALLER__.file}, at line #{Keyword.fetch!(meta, :line)}")
        ast = {:case, meta, [replacing_var, [do: clauses]]}
        {:raw, ast}

      _ ->
        {:fn, ast}
    end
  end

  def remove_fn(replacing_var, ast) do
    case ast do
      {:fn, _meta, [{:->, _, [[pat], clause]}]} ->
        #_ = IO.puts("fn detected in file #{__CALLER__.file}, at line #{Keyword.fetch!(meta, :line)}")
        #_ = IO.inspect(ast)
        #_ = IO.puts(Macro.to_string(pat))
        #_ = IO.puts(Macro.to_string(clause))
        case pat do
          {n, _, c} = target_var when is_var(target_var) ->
            ast = Macro.postwalk(clause, fn
              {^n, _, ^c} -> replacing_var
              other -> other
            end)
          {:raw, ast}

          other ->
            {:fn, other}
        end

      {:fn, _meta, _ast} ->
        #_ = IO.puts("fn multi_clause detected in file #{__CALLER__.file}, at line #{Keyword.fetch!(meta, :line)}")
        #_ = IO.inspect(ast)
        #_ = IO.puts(Macro.to_string(f))
        {:fn, ast}

      other ->
        {:fn, other}
    end
  end
end
