defmodule Eff do
  def runEff(action) do
    {action}
  end

  def perform(action, input) do
    {action, input}
  end

  def value(x) do
    {x}
  end

  def value2(x) do
    function(fn {} -> pure(x) end)
  end

  def function(f) do
    {f}
  end

  def function2(f) do
    operation(fn x, k -> k.(f.(x)) end)
  end

  def operation(with_k) do
    {with_k}
  end

  def handler(handler, action) do
    {handler, action}
  end

  def handlerRet(ret, handler, action) do
    {ret, handler, action}
  end

  def handlerLocal(x, handler, action) do
    {x, handler, action}
  end

  def handleLocalRet(x, ret, handler, action) do
    {x, ret, handler, action}
  end

  def handlerHide(handler, action) do
    {handler, action}
  end

  def pure(input) do
    {Pure, input}
  end

  def _Bind(input, continuation) do
    {input, continuation}
  end

  def _Pure(input) do
    {input}
  end

  def _PureFrom(input) do
    input
  end
end
