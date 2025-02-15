title = "Simple countdown."

inputs = %{
  "10_000" => 10_000,
}

contenders = %{
  "pure" => fn input -> Count.pure(input) end,
  #"ev_eff_state" => fn input -> Count.ev_state(input) end,
  "ev_local" => fn input -> Count.ev_local(input) end,
  #"ev_flocal" => fn input -> Count.ev_flocal(input) end,
  "trans" => fn input -> Count.trans(input) end,
  #"freer" => fn input -> Count.freer(input) end,
  "freer_q" => fn input -> Count.freer_q(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
