title = "Count with use of state every 5 iteration."

inputs = %{
  "10_000" => 10_000,
}

contenders = %{
  # "pure" => fn input -> Count5.pure(input) end,
  # "ev_local" => fn input -> Count5.ev_local(input) end,
  "ev_state" => fn input -> Count5.ev_state(input) end,
  # "ev_eff_fun" => fn input -> Count5.ev_fun(input) end,
  "trans" => fn input -> Count5.trans(input) end,
  "freer" => fn input -> Count5.freer(input) end,
  "freer_q" => fn input -> Count5.freer_q(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
