title = "Count with use of state every 5 iteration."

inputs = %{
  "10_000" => 10_000,
  "100" => 100,
  "10_000_000" => 10_000_000,
}

contenders = %{
  #"pure" => fn input -> Count5.pure(input) end,

  "ev_local" => fn input -> Count5.ev_local(input, &Utils.reduceMEff/3) end,
  #"ev_flocal" => fn input -> Count5.ev_flocal(input, &Utils.reduceMEff/3) end,

  #"trans" => fn input -> Count5.trans(input, &Utils.reduceMTrans/3) end,

  #"freer" => fn input -> Count5.freer(input, &Utils.reduceMFreer/3) end,
  "freer_q" => fn input -> Count5.freer_q(input, &Utils.reduceMFreerQ/3) end,

  #"ev_local_custom_reduce" => fn input -> Count5.ev_local(input, &Utils.rreduceMEff/3) end,
  #"ev_flocal_custom_reduce" => fn input -> Count5.ev_flocal(input, &Utils.rreduceMEff/3) end,
  #"freer_q_custom_reduce" => fn input -> Count5.freer_q(input, &Utils.rreduceMFreerQ/3) end,

  #"ev_state" => fn input -> Count5.ev_state(input) end,
}

Benchee.run(contenders, inputs: inputs, title: title)
