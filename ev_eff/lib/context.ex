defmodule Context.CNil do
  @enforce_keys []
  defstruct @enforce_keys

  defmacro cnil do
    quote do
      #%unquote(__MODULE__){}
      unquote(__MODULE__)
    end
  end
end

defmodule Context.CCons do
  @enforce_keys [
    :marker,
    :handler,
    :transformer,
    :context,
  ]
  defstruct @enforce_keys

  defmacro ccons(marker, handler, transformer, context) do
    quote do
      #%unquote(__MODULE__){
      #  marker: unquote(marker),
      #  handler: unquote(handler),
      #  transformer: unquote(transformer),
      #  context: unquote(context),
      #}
      {
        unquote(__MODULE__),
        unquote(marker),
        unquote(handler),
        unquote(transformer),
        unquote(context),
      }
    end
  end
end

defprotocol Context do
  def appropriate?(selector, context)
  def selectOp(selector, context)
end
