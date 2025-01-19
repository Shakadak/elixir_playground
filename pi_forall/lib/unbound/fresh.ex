defmodule Unbound.Fresh do
  defmacro raise_unimplemented do
    quote do
      case :rand.uniform(1) do
        1 ->
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: "#{inspect(__ENV__.module)}.#{inspect(__ENV__.function)} unimplemented"
        _ -> {}
      end
    end
  end

  def bind(_m, _f) do
    raise_unimplemented()
  end

  def pure(_x) do
    raise_unimplemented()
  end
end
