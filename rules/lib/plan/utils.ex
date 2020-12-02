defmodule Plan.Utils.Rules do

  def save_log(log, module, opts \\ []) do
    if !opts[:ignore_logs] do
      log = log
            |> Map.put(:graph, module.graph())
            |> Map.put(:type, module)
      hash = to_string(log)
      #void3(:rules_logs, hash, log)
      hash
    end
  end

  defmacro put_if(map, cond?, key, value) do
    quote do
      if (unquote(cond?)) do
        Map.put(unquote(map), unquote(key), unquote(value))
      else
        unquote(map)
      end
    end
  end
end
