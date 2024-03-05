defmodule Control.Exception do
  def mask(fun) do
    prev_trap = Process.flag(:trap_exit, true)
    restore = fn ->
      receive do
        {:EXIT, _from, reason} -> exit(reason)
      after
        0 -> Process.flag(:trap_exit, prev_trap)
      end
    end
    fun.(restore)
  end
end
