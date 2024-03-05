defmodule Rollback.Test.Roadmap1 do
  def test do
    IO.puts("HOLEY test")
    Process.sleep(500)
  end
  def process_vm do
    IO.puts("HOLEY process_vm")
    Process.sleep(500)
  end
  def end_vm do
    raise "Error in end_vm :'("
  end
  def reverse_test do
    IO.puts("Reverse test")
  end
  def reverse_process_vm do
    IO.puts("Reverse process_vm")
  end

  def roadmap do
    try do
      test()
      try do
        process_vm()
        try do
          end_vm()
        catch
          _, _ ->
            reverse_process_vm()
            reverse_test()
            :failed
        end
      catch
        _, _ ->
          reverse_test()
          :failed
      end
    catch
      _, _ ->
        :failed
    end
  end
end

defmodule Rollback.Test.Roadmap2 do
  def test do
    run = fn ->
      IO.puts("HOLEY test")
      Process.sleep(500)
    end
    rollback = fn ->
      IO.puts("Reverse test")
    end
    {run, rollback}
  end

  def process_vm do
    run = fn ->
      IO.puts("HOLEY process_vm")
      Process.sleep(500)

    end
    rollback = fn ->
      IO.puts("Reverse process_vm")
    end
    {run, rollback}
  end

  def end_vm do
    run = fn ->
      raise "Error in end_vm :'("
    end
    rollback = fn ->
      IO.puts("Reverse end_vm")
    end
    {run, rollback}
  end

  def roadmap do
    rollback = [fn -> :failed end]
    {run_test, rollback_test} = test()
    try do
      rollback = [rollback_test] ++ rollback

      run_test.()

      {run_process_vm, rollback_process_vm} = process_vm()
      try do
        rollback = [rollback_process_vm] ++ rollback

        run_process_vm.()

        {run_end_vm, rollback_end_vm} = end_vm()
        try do
          rollback = [rollback_end_vm] ++ rollback
          _ = rollback

          run_end_vm.()
        catch
          _, _ ->
            Enum.reduce(rollback, {}, fn rb, _ -> rb.() end)
        end
      catch
        _, _ ->
          Enum.reduce(rollback, {}, fn rb, _ -> rb.() end)
      end
    catch
      _, _ ->
        Enum.reduce(rollback, {}, fn rb, _ -> rb.() end)
    end
  end
end

defmodule Rollback.Test.Roadmap3 do
  def test do
    IO.puts("HOLEY test")
    Process.sleep(500)
    mk_done({}, fn ->
      IO.puts("Reverse test")
      Process.sleep(500)
    end)
  end

  def process_vm do
    IO.puts("HOLEY process_vm")
    Process.sleep(500)
    mk_done({}, fn ->
      IO.puts("Reverse process_vm")
      Process.sleep(500)
    end)
  end

  def end_vm do
    raise "Error in end_vm :'("
    Process.sleep(500)
    mk_done({}, fn ->
      IO.puts("Reverse end_vm")
      Process.sleep(500)
    end)
  end

  def mk_done(x, rb) do
    {:done, [rb], x}
  end

  def update_rbs({:done, rbs, x}, f), do: {:done, f.(rbs), x}

  def cat_rb(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def roadmap do
    rollback_init = [fn -> :failed end]

    something = fn rollback, f ->
      try do
        cat_rb(f.(), rollback)
      catch
        _, _ -> {:aborted, rollback}
      end
    end

    then = fn
      {:done, rbs, x}, f -> f.(rbs, x)
      {:aborted, rbs}, _ -> {:aborted, rbs}
    end

    something.(rollback_init, &test/0)
    |> then.(fn rbs, _ -> something.(rbs, &process_vm/0) end)
    |> then.(fn rbs, _ -> something.(rbs, &end_vm/0) end)
    |> case do
      {:done, _, x} -> {:ok, x}
      {:aborted, rbs} ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, y}
    end
  end
end

defmodule Rollback.Test.Roadmap4 do
  def test do
    try do
      IO.puts("HOLEY test")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse test")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, [fn -> :failed end]}
    end
  end

  def process_vm do
    try do
      IO.puts("HOLEY process_vm")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse process_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, [fn -> :failed end]}
    end
  end

  def end_vm do
    try do
      raise "Error in end_vm :'("
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse end_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, [fn -> :failed end]}
    end
  end

  def mk_done(x, rb) do
    {:done, {[rb], x}}
  end

  def update_rbs({:done, {rbs, x}}, f), do: {:done, {f.(rbs), x}}
  def update_rbs({:aborted, rbs}, f), do: {:aborted, f.(rbs)}

  def cat_rbs(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def then(x, f) do
    case x do
      {:done, rbs, x} -> f.(rbs, x)
      {:aborted, rbs} -> {:aborted, rbs}
    end
  end

  def run_rollback(x) do
    case x do
      {:done, _, x} -> {:ok, x}
      {:aborted, rbs} ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, y}
    end
  end

  def roadmap do
    rbs_last = [fn -> :failed end]
    case test() do
      {:done, {rbs1, _x}} ->
        case process_vm() do
          {:done, {rbs2, _x}} ->
            end_vm()
            |> cat_rbs(rbs2)
          {:aborted, _} = x -> x
        end
        |> cat_rbs(rbs1)
      {:aborted, _} = x -> x
    end
    |> cat_rbs(rbs_last)
  end
end

defmodule Rollback.Test.Roadmap5 do
  def test do
    try do
      IO.puts("HOLEY test")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse test")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, []}
    end
  end

  def process_vm do
    try do
      IO.puts("HOLEY process_vm")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse process_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, []}
    end
  end

  def end_vm do
    try do
      raise "Error in end_vm :'("
      Process.sleep(500)
      :finished
      |> mk_done(fn ->
        IO.puts("Reverse end_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> {:aborted, []}
    end
  end

  def mk_done(x, rb) do
    {:done, {[rb], x}}
  end

  def update_rbs({:done, {rbs, x}}, f), do: {:done, {f.(rbs), x}}
  def update_rbs({:aborted, rbs}, f), do: {:aborted, f.(rbs)}

  def cat_rbs(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def then_rb(x, f) do
    case x do
      {:done, {rbs, x}} -> f.(x) |> cat_rbs(rbs)
      {:aborted, rbs} -> {:aborted, rbs}
    end
  end

  def run_rollback(x) do
    case x do
      {:done, {_, x}} -> {:ok, x}
      {:aborted, rbs} ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, y}
    end
  end

  def roadmap do
    mk_done({}, fn -> :failed end)
    |> then_rb(fn _ -> test() end)
    |> then_rb(fn _ -> process_vm() end)
    |> then_rb(fn _ -> end_vm() end)
  end
end

defmodule Rollback.Test.Roadmap6 do
  defmacro compute(do: {:__block__, _context, body}) do
    rec_mdo(body)
  end

  def rec_mdo([{:<-, context, _}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic do should be a monadic value"
  end

  def rec_mdo([line]) do
    line
  end

  def rec_mdo([{:<-, _context, [binding, expression]} | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn unquote(binding) ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  def rec_mdo([{:=, _context, [_binding, _expression]} = line | tail]) do
    quote do
      unquote(line)
      unquote(rec_mdo(tail))
    end
  end

  def rec_mdo([expression | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn _ ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  defmacro done(rbs, x), do: {rbs, {:done, x}}
  defmacro aborted(rbs, reason), do: {rbs, {:aborted, reason}}

  def test do
    try do
      IO.puts("HOLEY test")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse test")
        Process.sleep(500)
      end)
    catch
      _, _ -> abort("smthg")
    end
  end

  def process_vm do
    try do
      IO.puts("HOLEY process_vm")
      Process.sleep(500)
      {}
      |> mk_done(fn ->
        IO.puts("Reverse process_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> abort("smthg")
    end
  end

  def end_vm do
    try do
      raise "Error in end_vm :'("
      Process.sleep(500)
      :finished
      |> mk_done(fn ->
        IO.puts("Reverse end_vm")
        Process.sleep(500)
      end)
    catch
      _, _ -> abort("smthg")
    end
  end

  def abort(reason), do: aborted([], reason)

  def mk_done(x, rb), do: done([rb], x)

  def update_rbs({rbs, x}, f), do: {f.(rbs), x}
  def put_rbs(x, rbs), do: update_rbs(x, fn _ -> rbs end)
  def get_rbs({rbs, _}), do: rbs

  def cat_rbs(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def map(mx, f) do
    case mx do
      done(rbs, x)-> done(rbs, f.(x))
      aborted(_, _) = x -> x
    end
  end

  def pure(x), do: done([], x)

  #def ap(mf, mx) do
  #  case mf do
  #    done(rbsf, f) ->
  #      mx
  #      |> map(f)
  #      |> cat_rbs(rbsf)

  #    aborted(rbs, reason) ->
  #      aborted(get_rbs(mx) ++ rbs, reason)
  #  end
  #end

  #def lift_a2(f, mx, my) do
  #  case {mx, my} do
  #    {done(rbsx, x), done(rbsy, y)} -> done(rbsy ++ rbsx, f.(x, y))
  #    {done(rbsx, _), aborted(rbsy, reason)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), done(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), aborted(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #  end
  #end

  def then_rb(mx, f) do
    case mx do
      done(rbs, x) -> f.(x) |> cat_rbs(rbs)
      aborted(_, _) = x -> x
    end
  end

  def bind(mx, f), do: then_rb(mx, f)

  def tell(rbs), do: done(rbs, {})

  def rb(rb), do: tell([rb])

  def run_rollback(x) do
    case x do
      done(_, x) -> {:ok, x}
      aborted(rbs, reason) ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, {y, reason}}
    end
  end

  def roadmap do
    compute do
      rb fn -> :failed end
      test()
      process_vm()
      end_vm()
    end
  end
end

defmodule Rollback.Test.Roadmap7 do
  defmacro compute(do: {:__block__, _context, body}) do
    rec_mdo(body)
  end

  def rec_mdo([{:<-, context, _}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic do should be a monadic value"
  end

  def rec_mdo([line]) do
    line
  end

  def rec_mdo([{:<-, _context, [binding, expression]} | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn unquote(binding) ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  def rec_mdo([{:=, _context, [_binding, _expression]} = line | tail]) do
    quote do
      unquote(line)
      unquote(rec_mdo(tail))
    end
  end

  def rec_mdo([expression | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn _ ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  defmacro done(rbs, x), do: {rbs, {:done, x}}
  defmacro aborted(rbs, reason), do: {rbs, {:aborted, reason}}

  def test do
    script = fn ->
      IO.puts("HOLEY test")
      Process.sleep(500)
      {}
    end
    rollback = fn ->
        IO.puts("Reverse test")
        Process.sleep(500)
      end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def process_vm do
    script = fn ->
      IO.puts("HOLEY process_vm")
      Process.sleep(500)
      {}
    end
    rollback = fn ->
      IO.puts("Reverse process_vm")
      Process.sleep(500)
    end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def end_vm do
    script = fn ->
      raise "Error in end_vm :'("
      Process.sleep(500)
      :finished
    end
    rollback = fn ->
      IO.puts("Reverse end_vm")
      Process.sleep(500)
    end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def abort(reason), do: aborted([], reason)

  def mk_done(x, rb), do: done([rb], x)

  def attempt(script, rollback, on_error) do
    try do
      script.()
      |> mk_done(rollback)
    catch
      kind, data -> abort(on_error.(kind, data))
    end
  end

  def update_rbs({rbs, x}, f), do: {f.(rbs), x}
  def put_rbs(x, rbs), do: update_rbs(x, fn _ -> rbs end)
  def get_rbs({rbs, _}), do: rbs

  def cat_rbs(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def map(mx, f) do
    case mx do
      done(rbs, x)-> done(rbs, f.(x))
      aborted(_, _) = x -> x
    end
  end

  def pure(x), do: done([], x)

  #def ap(mf, mx) do
  #  case mf do
  #    done(rbsf, f) ->
  #      mx
  #      |> map(f)
  #      |> cat_rbs(rbsf)

  #    aborted(rbs, reason) ->
  #      aborted(get_rbs(mx) ++ rbs, reason)
  #  end
  #end

  #def lift_a2(f, mx, my) do
  #  case {mx, my} do
  #    {done(rbsx, x), done(rbsy, y)} -> done(rbsy ++ rbsx, f.(x, y))
  #    {done(rbsx, _), aborted(rbsy, reason)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), done(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), aborted(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #  end
  #end

  def then_rb(mx, f) do
    case mx do
      done(rbs, x) -> f.(x) |> cat_rbs(rbs)
      aborted(_, _) = x -> x
    end
  end

  def bind(mx, f), do: then_rb(mx, f)

  def tell(rbs), do: done(rbs, {})

  def rb(rb), do: tell([rb])

  def run_rollback(x) do
    case x do
      done(_, x) -> {:ok, x}
      aborted(rbs, reason) ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, {y, reason}}
    end
  end

  def roadmap do
    compute do
      rb fn -> :failed end
      test()
      process_vm()
      end_vm()
    end
  end
end

defmodule Rollback.Test.Roadmap8 do
  defmacro compute(do: {:__block__, _context, body}) do
    rec_mdo(body)
  end

  def rec_mdo([{:<-, context, _}]) do
    raise "Error line #{Keyword.get(context, :line, :unknown)}: end of monadic do should be a monadic value"
  end

  def rec_mdo([line]) do
    line
  end

  def rec_mdo([{:<-, _context, [binding, expression]} | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn unquote(binding) ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  def rec_mdo([{:=, _context, [_binding, _expression]} = line | tail]) do
    quote do
      unquote(line)
      unquote(rec_mdo(tail))
    end
  end

  def rec_mdo([expression | tail]) do
    quote do
      unquote(expression)
      |> unquote(__MODULE__).bind(fn _ ->
        unquote(rec_mdo(tail))
      end)
    end
  end

  defmacro done(rbs, x), do: {rbs, {:done, x}}
  defmacro aborted(rbs, reason), do: {rbs, {:aborted, reason}}

  def test do
    script = fn ->
      IO.puts("HOLEY test")
      Process.sleep(500)
      {}
    end
    rollback = fn ->
        IO.puts("Reverse test")
        Process.sleep(500)
      end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def process_vm do
    script = fn ->
      IO.puts("HOLEY process_vm")
      Process.sleep(500)
      {}
    end
    rollback = fn ->
      IO.puts("Reverse process_vm")
      Process.sleep(500)
    end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def end_vm do
    script = fn ->
      raise "Error in end_vm :'("
      Process.sleep(500)
      :finished
    end
    rollback = fn ->
      IO.puts("Reverse end_vm")
      Process.sleep(500)
    end
    on_error = fn _, _ -> "smthg" end
    attempt(script, rollback, on_error)
  end

  def abort(reason), do: aborted([], reason)

  def mk_done(x, rb), do: done([rb], x)

  def attempt(script, rollback, on_error) do
    try do
      script.()
      |> mk_done(rollback)
    catch
      kind, data -> abort(on_error.(kind, data))
    end
  end

  def update_rbs({rbs, x}, f), do: {f.(rbs), x}
  def put_rbs(x, rbs), do: update_rbs(x, fn _ -> rbs end)
  def get_rbs({rbs, _}), do: rbs

  def cat_rbs(dn, rcs), do: update_rbs(dn, & &1 ++ rcs)

  def map(mx, f) do
    case mx do
      done(rbs, x)-> done(rbs, f.(x))
      aborted(_, _) = x -> x
    end
  end

  def pure(x), do: done([], x)

  #def ap(mf, mx) do
  #  case mf do
  #    done(rbsf, f) ->
  #      mx
  #      |> map(f)
  #      |> cat_rbs(rbsf)

  #    aborted(rbs, reason) ->
  #      aborted(get_rbs(mx) ++ rbs, reason)
  #  end
  #end

  #def lift_a2(f, mx, my) do
  #  case {mx, my} do
  #    {done(rbsx, x), done(rbsy, y)} -> done(rbsy ++ rbsx, f.(x, y))
  #    {done(rbsx, _), aborted(rbsy, reason)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), done(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #    {aborted(rbsx, reason), aborted(rbsy, _)} -> aborted(rbsy ++ rbsx, reason)
  #  end
  #end

  def then_rb(mx, f) do
    case mx do
      done(rbs, x) -> f.(x) |> cat_rbs(rbs)
      aborted(_, _) = x -> x
    end
  end

  def bind(mx, f), do: then_rb(mx, f)

  def tell(rbs), do: done(rbs, {})

  def rb(rb), do: tell([rb])

  def run_rollback(x) do
    case x do
      done(_, x) -> {:ok, x}
      aborted(rbs, reason) ->
        y = Enum.reduce(rbs, {}, fn rb, _ -> rb.() end)
        {:error, {y, reason}}
    end
  end

  def roadmap do
    compute do
      rb fn -> :failed end
      test()
      process_vm()
      end_vm()
    end
  end
end
