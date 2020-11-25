defmodule Base do
  defmacro open(module, only: only, except: except, do: ast) do
    do_open(module, %{only: only, except: except}, ast, __CALLER__)
  end
  defmacro open(module, only: only, do: ast) do
    do_open(module, %{only: only}, ast, __CALLER__)
  end
  defmacro open(module, except: except, do: ast) do
    do_open(module, %{except: except}, ast, __CALLER__)
  end
  defmacro open(module, do: ast) do
    do_open(module, %{}, ast, __CALLER__)
  end
  defmacro open(module, ast) do
    do_open(module, %{}, ast, __CALLER__)
  end
  defmacro open(module, [only: only, except: except], do: ast) do
    do_open(module, %{only: only, except: except}, ast, __CALLER__)
  end
  defmacro open(module, [only: only], do: ast) do
    do_open(module, %{only: only}, ast, __CALLER__)
  end
  defmacro open(module, [except: except], do: ast) do
    do_open(module, %{except: except}, ast, __CALLER__)
  end

  def do_open(module, opts, ast, caller) do
    module = Macro.expand(module, caller)

    ast = if module == caller.module do
      do_open_on_self(module, ast)
    else
      do_open_go(module, opts, ast, caller)
    end

    ast
    |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  def do_open_on_self(module, ast) do
    updated_ast = Macro.prewalk(ast, fn
      {_, _, _} = x ->
        Macro.update_meta(x, fn m -> Keyword.put(m, :import, module) end)

      x -> x
    end)

    updated_ast
  end

  def do_open_go(module, opts, ast, _caller) do
    only = Map.get(opts, :only, [])
    except = Map.get(opts, :except, [])

    functions = 
      module.__info__(:functions)
      |> Enum.filter(fn x when only != [] -> x in only ; _ -> true end)
      |> Enum.filter(fn x -> x not in except end)

    macros = 
      module.__info__(:macros)
      |> Enum.filter(fn x when only != [] -> x in only ; _ -> true end)
      |> Enum.filter(fn x -> x not in except end)

    name_x_arity = functions ++ macros

    _ = if {:open, 2} in name_x_arity or {:open, 3} in name_x_arity do
      require Logger
      _ = Logger.warn("Warning: open/2,3 in #{inspect(module)} may override inner uses of Base.open/2,3 macro")
    end

    updated_ast = Macro.prewalk(ast, fn
      {name, _, xs} = x when is_list(xs) ->
        if {name, length(xs)} in name_x_arity do
          Macro.update_meta(x, fn m -> Keyword.put(m, :import, module) end)
        else
          x
        end

      x -> x
    end)

    quote do
      import unquote(module), unquote(Map.to_list(opts))
      unquote(updated_ast)
    end
  end
  #def do_open_without_info()
  #def do_open_with_info()
end

defmodule Base.Curry do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__), only: [defcurried: 2, defoverridable_curried: 2]
    end
  end

  defmacro __before_compile__(_) do
    functions =
      Enum.reverse(Module.get_attribute(__CALLER__.module, :defcurried_accumulator, []))
      |> Enum.map(fn {call, body} -> {name_x_arity(call), call, body} end)
      |> Enum.chunk_by(fn {name_x_arity, _call, _body} -> name_x_arity end)
      |> Enum.map(fn xs -> Enum.group_by(xs, fn {name_x_arity, _call, _body} -> name_x_arity end, fn {_name_x_arity, call, body} -> {call, body} end) end)
      |> Enum.map(&Enum.to_list/1)
      |> Enum.map(fn [x] -> x end)

    names = MapSet.new(functions, fn {nxa, _} -> elem(nxa, 0) end)

    overridable_functions =
      Enum.reverse(Module.get_attribute(__CALLER__.module, :defoverridable_curried_accumulator, []))
      |> Enum.filter(fn {call, _} -> not (elem(name_x_arity(call), 0) in names) end)
      |> Enum.map(fn {call, body} -> {name_x_arity(call), call, body} end)
      |> Enum.chunk_by(fn {name_x_arity, _call, _body} -> name_x_arity end)
      |> Enum.map(fn xs -> Enum.group_by(xs, fn {name_x_arity, _call, _body} -> name_x_arity end, fn {_name_x_arity, call, body} -> {call, body} end) end)
      |> Enum.map(&Enum.to_list/1)
      |> Enum.map(fn [x] -> x end)

    Enum.concat(functions, overridable_functions)
    |> Enum.flat_map(fn {{name, arity}, defs} ->
      proto_args = Enum.map(1..arity, fn n -> {:"arg#{n}", [], nil} end)
      body = to_body(proto_args, defs)
      defs = Enum.flat_map(arity..0, fn n ->
        case Enum.split(proto_args, n) do
          {_args, []} ->
            Enum.map(defs, fn {call, body} ->
              quote do
                def unquote(call) do
                  unquote(body)
                end
              end
            end)

          {args, following_args} ->
            body = List.foldr(following_args, body, fn arg, body -> quote do: fn unquote(arg) -> unquote(body) end end)
            [quote do
              def unquote({name, [], args}) do
                unquote(body)
              end
            end]
        end
      end)

      defs
    end)
    |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  def name_x_arity({:when, _, [{name, _, args} | _ ]}), do: {name, Enum.count(args)}
  def name_x_arity({name, _metadata, args}), do: {name, Enum.count(args)}

  def to_body(proto_args, defs) do
    clauses = Enum.flat_map(defs, fn {call, body} ->
      stripped_call = case call do
        {:when, metadata, [{_name, _, args} | guards]} ->
          as_tuple = quote do: {unquote_splicing(args)}
          {:when, metadata, [as_tuple | guards]}

        {_name, _, args} ->
          quote do: {unquote_splicing(args)}
      end

      quote do
        unquote(stripped_call) -> unquote(body)
      end
    end)

    quote do
      case {unquote_splicing(proto_args)} do
        unquote(clauses)
      end
    end
  end

  defmacro defcurried(call, do: body)do
    attribute = :defcurried_accumulator
    _ = Module.register_attribute(__CALLER__.module, attribute, accumulate: true)
    _ = Module.put_attribute(__CALLER__.module, attribute, {call, body})
  end

  defmacro defoverridable_curried(call, do: body)do
    attribute = :defoverridable_curried_accumulator
    _ = Module.register_attribute(__CALLER__.module, attribute, accumulate: true)
    _ = Module.put_attribute(__CALLER__.module, attribute, {call, body})
  end
end

defmodule Base.Data.Function do
  use Base.Curry

  defcurried const(a, _), do: a
end
