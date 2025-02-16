title = "Traversal with error at the end."

inputs = %{
  "10_000" => List.duplicate(1, 10_000) ++ [0],
  "early_10_000" => [0] ++ List.duplicate(1, 10_000),
}

contenders = %{
  #"pure" => fn input -> Error.pure(input, &Enum.reduce/3) end,

  "ev_either" => fn input -> Error.ev_either(input, &Utils.reduceMEff/3) end,

  #"trans" => fn input -> Error.trans(input, &Utils.reduceMTrans/3) end,

  #"freer" => fn input -> Error.freer(input, &Utils.reduceMFreer/3) end,
  "freer_q" => fn input -> Error.freer_q(input, &Utils.reduceMFreerQ/3) end,

  "ev_either_fold" => fn input -> Error.ev_either(input, &Utils.foldMEff/3) end,
  "freer_q_fold" => fn input -> Error.freer_q(input, &Utils.foldMFreerQ/3) end,

  "ev_either_custom_reduce" => fn input -> Error.ev_either(input, &Utils.rreduceMEff/3) end,
  "freer_q_custom_reduce" => fn input -> Error.freer_q(input, &Utils.rreduceMFreerQ/3) end,

  # "ev_maybe" => fn input -> Error.ev_maybe(input) end,
  #"ev_default_fold" => fn input -> Error.ev_default(input, &Utils.foldMEff/3) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
