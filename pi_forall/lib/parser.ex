defmodule Parser do
  def new_pos(_location, _line, _column) do
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
