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
      defmacro unquote({name, meta, [:viewing | args]}) do
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
      defmacro unquote({name, meta, [:viewing | args]}) do
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
    _ = IO.inspect(ast, label: "unrecognizable pattern")
    raise("pattern not recognized")
  end

  # TODO : when using
  # view x do
  #   <pattern>(...) -> ...
  # end
  # call the pattern with an added argument telling the macro that it is in a match

  # Utils

  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false
end
