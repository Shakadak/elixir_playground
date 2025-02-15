title = "Traversal with error at the end."

inputs = %{
  "10_000" => List.duplicate(1, 10_000) ++ [0],
}

contenders = %{
  # "pure" => fn input -> Error.pure(input) end,
  # "ev_maybe" => fn input -> Error.ev_maybe(input) end,
  "ev_either" => fn input -> Error.ev_either(input) end,
  # "ev_default" => fn input -> Error.ev_default(input) end,
  "trans" => fn input -> Error.trans(input) end,
  "freer" => fn input -> Error.freer(input) end,
  "freer_q" => fn input -> Error.freer_q(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
