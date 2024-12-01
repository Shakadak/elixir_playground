defmodule Clos do
  @enforce_keys [
    :env,
    :var,
    :body,
  ]
  defstruct @enforce_keys

  defmacro clos(env, var, body) do
    quote do
      %unquote(__MODULE__){
        env: unquote(env),
        var: unquote(var),
        body: unquote(body)
      }
    end
  end

  @type t :: %__MODULE__{
    env: Nbe.environment,
    var: Nbe.symbol,
    body: any,
  }
end
