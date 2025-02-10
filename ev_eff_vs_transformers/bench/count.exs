title = "Simple countdown."

inputs = %{
  "10_000" => 10_000,
}

contenders = %{
  # "pure" => fn input -> Count.pure(input) end,
  "ev_eff_ets" => fn input -> Count.ev_ets(input) end,
  # "ev_eff_fun" => fn input -> Count.ev_fun(input) end,
  "trans" => fn input -> Count.trans(input) end,
  "freer" => fn input -> Count.freer(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
