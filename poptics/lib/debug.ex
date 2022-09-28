defmodule Debug do
  @spec source(module) :: iolist
  def source(module) do
    path = :code.which(module)
    {:ok, {_, [{:abstract_code, {_, ac}}]}} = :beam_lib.chunks(path, [:abstract_code])
    :erl_prettypr.format(:erl_syntax.form_list(ac))
  end
end