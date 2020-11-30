defmodule PatternMetonyms do
  @moduledoc """
  Documentation for `PatternMetonyms`.
  """

  @doc """
  implicit bidirectional
  target : pattern just2(a, b) = just({a, b})
  currently work as is for that kind of complexity

  unidirectional
  target : pattern head(x) <- [x | _]
  but doesn't work as is
  "pattern(head(x) <- [x | _])"

  explicit bidirectional
  target : pattern polar(r, a) <- (pointPolar -> {r, a}) when polar(r, a) = polarPoint(r, a)
  but doesn't work as is
  "pattern (polar(r, a) <- (pointPolar -> {r, a})) when polar(r, a) = polarPoint(r, a) "
  """
  # implicit bidirectional
  # lhs = {:just2, [], [{:a, [], Elixir}, {:b, [], Elixir}]}  # just2(a, b)
  # pat = {:just, [], [{{:a, [], Elixir}, {:b, [], Elixir}}]} # just({a, b})
  defmacro pattern(_syn = {:=, _, [lhs, pat]}) do
    # _ = IO.inspect(syn, label: "implicit bidirectional(syn)")
    # _ = IO.inspect(lhs, label: "implicit bidirectional(lhs)")
    # _ = IO.inspect(pat, label: "implicit bidirectional(pat)")
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional / with view
  defmacro pattern(syn = {:<-, _, [lhs, view = [{:->, _, [[fun], pat]}]]}) do
    _ = IO.inspect(syn,  label: "implicit bidirectional(syn)")
    _ = IO.inspect(lhs,  label: "unidirectional(lhs)")
    _ = IO.inspect(view, label: "unidirectional(view)")
    _ = IO.inspect(fun,  label: "unidirectional(fun)")
    _ = IO.inspect(pat,  label: "unidirectional(pat)")
  end

  # unidirectional
  # lhs = {:head, [], [{:x, [], Elixir}]}                  # head(x)
  # pat = [{:|, [], [{:x, [], Elixir}, {:_, [], Elixir}]}] # [x | _]
  defmacro pattern({:<-, _, [lhs, pat]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # explicit bidirectional / with view
  # lhs = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}       # polar(r, a)
  # fun = {:pointPolar, [], Elixir}                                # pointPolar
  # pat = {{:r, [], Elixir}, {:a, [], Elixir}}                     # {r, a}
  # lhs2 = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}      # polar(r, a)
  # expr = {:polarPoint, [], [{:r, [], Elixir}, {:a, [], Elixir}]} # polarPoint(r, a)
  defmacro pattern(where = {:when, _, [link = {:<-, _, [lhs, view = [{:->, _, [[fun], pat]}]]}, builder = {:=, _, [lhs2, expr]}]}) do
    _ = IO.inspect(where,   label: "explicit bidirectional(where)")
    _ = IO.inspect(link,    label: "explicit bidirectional(link)")
    _ = IO.inspect(lhs,     label: "explicit bidirectional(lhs)")
    _ = IO.inspect(view,    label: "explicit bidirectional(view)")
    _ = IO.inspect(fun,     label: "explicit bidirectional(fun)")
    _ = IO.inspect(pat,     label: "explicit bidirectional(pat)")
    _ = IO.inspect(builder, label: "explicit bidirectional(builder)")
    _ = IO.inspect(lhs2,    label: "explicit bidirectional(lhs2)")
    _ = IO.inspect(expr,    label: "explicit bidirectional(expr)")
  end

  # explicit bidirectional
  defmacro pattern(where = {:when, _, [link = {:<-, _, [lhs, pat]}, builder = {:=, _, [lhs2, expr]}]}) do
    _ = IO.inspect(where,   label: "explicit bidirectional(where)")
    _ = IO.inspect(link,    label: "explicit bidirectional(link)")
    _ = IO.inspect(lhs,     label: "explicit bidirectional(lhs)")
    _ = IO.inspect(pat,     label: "explicit bidirectional(pat)")
    _ = IO.inspect(builder, label: "explicit bidirectional(builder)")
    _ = IO.inspect(lhs2,    label: "explicit bidirectional(lhs2)")
    _ = IO.inspect(expr,    label: "explicit bidirectional(expr)")
  end

  defmacro pattern(ast) do
    raise("pattern not recognized: #{Macro.to_string(ast)}")
  end

  # TODO : when using
  # view x do
  #   <pattern>(...) -> ...
  # end
  # call the pattern with an added argument telling the macro that it is in a match
  #defmacro view(value, do: {:__block__, _, clauses}) do
  #  _ = IO.inspect(value, label: "view block value")
  #  _ = IO.inspect(clauses, label: "view block clauses")
  #  :ok
  #end

  defmacro view(data, do: clauses) when is_list(clauses) do
    [last | rev_clauses] = Enum.reverse(clauses)

    rev_tail = case last do
      {:->, _, [[lhs = {name, meta, con}], rhs]} when is_atom(name) and is_list(meta) and is_atom(con) ->
        # presumably a catch all pattern
        last_ast = quote do
          case unquote(data) do
            unquote(lhs) -> unquote(rhs)
          end
        end

        [last_ast]

      penultimate ->
        last_ast = quote do
          raise(CaseClauseError, term: unquote(data))
        end

        [last_ast, penultimate]
    end

    ast = Enum.reduce(rev_tail ++ rev_clauses, fn x, acc -> view_folder(x, acc, data, __CALLER__) end)

    ast
    #|> case do x -> _ = IO.puts("view:\n#{Macro.to_string(x)}") ; x end
  end

  def view_folder({:->, _, [[[{:->, _, [[{name, meta, nil}], pat]}]], rhs]}, acc, data, _caller_env) do
    call = {name, meta, [data]}
    quote do
      case unquote(call) do
        unquote(pat) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  def view_folder({:->, meta_clause, [[{name, meta, con} = call], rhs]}, acc, data, caller_env) when is_atom(name) and is_list(meta) and is_list(con) do
    augmented_call = {:"$pattern_metonyms_viewing_#{name}", meta, con}
    case Macro.expand(augmented_call, caller_env) do
      # didn't expand because didn't exist, so we let other macros do their stuff later
      ^augmented_call ->
        quote do
          case unquote(data) do
            unquote(call) -> unquote(rhs)
            _ -> unquote(acc)
          end
        end

      # can this recurse indefinitely ?
      new_call ->
        new_clause = {:->, meta_clause, [[new_call], rhs]}
        view_folder(new_clause, acc, data, caller_env)
    end
  end

  def view_folder({:->, _, [[lhs = {name, meta, con}], rhs]}, acc, data, _caller_env) when is_atom(name) and is_list(meta) and is_atom(con) do
    quote do
      case unquote(data) do
        unquote(lhs) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  def view_folder({:->, _, [[lhs], rhs]}, acc, data, _caller_env) do
    quote do
      case unquote(data) do
        unquote(lhs) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  # Utils

  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false
end
