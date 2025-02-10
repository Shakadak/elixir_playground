title = "Count with use of state every 5 iteration."

inputs = %{
  "10_000" => 10_000,
}

contenders = %{
  "pure" => fn input -> Count5.pure(input) end,
  "ev_eff_ets" => fn input -> Count5.ev_ets(input) end,
  # "ev_eff_fun" => fn input -> Count5.ev_fun(input) end,
  "trans" => fn input -> Count5.trans(input) end,
  "freer" => fn input -> Count5.freer(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
