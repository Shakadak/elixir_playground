defmodule Eff do
  import Bind

  import Context.{CCons, CNil}
  import Op

  defmacro eff(f) do
    {Eff, f}
  end

  def pure(x), do: eff(fn _ctx -> Ctl.pure(x) end)

  def bind(eff(eff), f) do
    eff(fn ctx ->
      m Ctl do
        ctl <- eff.(ctx)
        under(ctx, f.(ctl))
      end
    end)
  end

  def map(f, m1) do
    m Eff do
      x1 <- m1
      pure(f.(x1))
    end
  end

  @doc """
  under :: Context e -> Eff e a -> Ctl a
  """
  def under(ctx, eff(eff)), do: eff.(ctx)

  def runEff(eff(eff)) do
    Ctl.runCtl(eff.(cnil()))
  end

  def perform(selectOp, x) do
    eff(fn ctx ->
      case selectContext(ctx, selectOp) do
        {SubContext, ccons(m, h, t, ctx_)} ->
          case Context.selectOp(selectOp, h) do
            op(f) -> f.(m, t.(ctx_), x)
          end
      end
    end)
  end

  def selectContext(ccons(_m, h, _t, sub_ctx) = ctx, selector) do
    case Context.appropriate?(selector, h) do
      true -> {SubContext, ctx}
      false -> selectContext(sub_ctx, selector)
    end
  end

  def selectContext(cnil(), selector) do
    raise "Context not found for selector : #{inspect(selector)}"
  end

  def value(x) do
    function(fn {} -> pure(x) end)
  end

  def function(f) do
    op(fn _m, ctx, x -> under(ctx, f.(x)) end)
  end

  def function2(f) do
    operation(fn x, k -> k.(f.(x)) end)
  end

  @doc """
  operation :: (a -> (b -> Eff e ans) -> Eff e ans) -> Op a b e ans
  """
  def operation(f) do
    op(fn m, ctx, x ->
      Ctl.yield(m, fn ctlk ->
        k = fn y -> eff(fn ctx_ -> guard(ctx, ctx_, ctlk, y) end) end
        under(ctx, f.(x, k))
      end)
    end)
  end

  def guard(ctx, ctx, k, x), do: k.(x)
  def guard(ctx1, ctx2, _k, _x) do
    raise "unscoped resumption: #{inspect(ctx1)} != #{inspect(ctx2)}"
  end

  def handler(handler, action) do
    eff(fn ctx ->
      Ctl.prompt(fn m ->
        under(ccons(m, handler, & &1, ctx), action)
      end)
    end)
  end

  def mask(eff), do: eff(fn ccons(_m, _h, _t, ctx) -> under(ctx, eff) end)

  def handlerRet(ret, handler, action) do
    handler(handler, m Eff do x <- action ; pure(ret.(x)) end)
  end

  def handlerRetEff(ret, h, action) do
    handler(h, m Eff do x <- action ; mask(ret.(x)) end)
  end

  def handlerLocal(init, h, action) do
    Local.local(init, handlerHide(h, action))
  end

  def handlerLocalRet(init, ret, h, action) do
    Local.local(init, handlerHideRetEff(fn x ->
      m Eff do
        y <- Local.localGet()
        pure(ret.(x, y))
      end
    end, h, action))
  end

  def handlerHide(h, action) do
    eff fn ccons(m_, h_, g_, ctx_) ->
      Ctl.prompt fn m ->
        g = &ccons(m_, h_, g_, &1)
        under(ccons(m, h, g, ctx_), action)
      end
    end
  end

  def handlerHideRetEff(ret, h, action) do
    eff fn ccons(m_, h_, g_, ctx_) = ctx ->
      Ctl.prompt(fn m -> m Ctl do
        x <- under(ccons(m, h, &ccons(m_, h_, g_, &1), ctx_), action)
        under(ctx, ret.(x))
      end end)
    end
  end

  def _Bind(input, continuation) do
    bind(input, continuation)
  end
end
