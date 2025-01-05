defmodule Go do
  @enforce_keys [
    :result,
  ]
  defstruct @enforce_keys

  defmacro go(result) do
    quote do
      %unquote(__MODULE__){
        result: unquote(result),
      }
    end
  end

  @type t :: %__MODULE__{
    result: any,
  }

  defmacro go_on(chain, result) do
    go_on_go(chain, result)
  end

  def go_on_go([], result) do
    result
  end

  def go_on_go([[pat0, e0] | rest], result) do
    quote generated: true do
      case unquote(e0) do
        go(unquote(pat0)) -> unquote(__MODULE__).go_on(unquote(rest), unquote(result))
        go(v) -> raise "go_on: Pattern did not match value #{inspect(v)}"
        stop(expr, msg) -> stop(expr, msg)
      end
    end
  end
end
