defmodule TestMacro do
  require MyMacro

  MyMacro.macro Banana, name: :banana do
    IO.puts(:split)
  end
end
