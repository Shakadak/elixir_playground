defmodule Eff do
  import Bind

  import Context.{CCons, CNil}
  require Op

  require Ctl

  defmacro __using__([]) do
    quote do
      import Bind
      import Eff
      require Op
      require Ctl
    end
  end

  defmacro eff(f) do
    # {Eff, f}
    f
  end

  @doc """
  under :: Context e -> Eff e a -> Ctl a
  """
  defmacro under(ctx, eff), do: quote(do: unquote(eff).(unquote(ctx)))
  #def under(ctx, eff(eff)), do: eff.(ctx)

  defmacro pure(x) do
    quote do
      eff(fn _ctx ->
        Ctl.pure(unquote(x))
      end)
    end
  end

  defmacro bind(eff, f) do
    quote do
    eff(fn ctx ->
      m Ctl do
        ctl <- under(ctx, unquote(eff))
        under(ctx, unquote(f).(ctl))
      end
    end)
    end
  end

  defmacro _Bind(input, continuation) do
    quote do
      bind(unquote(input), unquote(continuation))
    end
    |> Eff.Internal.wrap(__CALLER__.module, __MODULE__, [:bind])
  end

  def map(f, m1) do
    bind(m1, fn a -> pure(f.(a)) end)
  end

  def runEff(eff(eff)) do
    ctl = eff.(cnil())
    Ctl.runCtl(ctl)
  end

  def perform(%impl{} = selectOp, x) do
    withSubcontext(fn ccons(m, h, t, ctx_) ->
      new_ctx = t.(ctx_)
      impl.runOp(selectOp, h, m, new_ctx, x)
    end, selectOp)
    # eff(fn ctx ->
    #   ccons(m, h, t, ctx_) = selectContext(ctx, selectOp)
    #   impl.runOp(selectOp, h, m, t.(ctx_), x)
    # end)
  end

  def withSubcontext(f, selectOp) do
    eff(fn ctx ->
      f.(selectContext(ctx, selectOp))
    end)
  end

  def selectContext(ccons(_m, h, _t, sub_ctx) = ctx, %impl{} = selector) do
    case impl.appropriate?(selector, h) do
      true -> ctx
      false -> selectContext(sub_ctx, selector)
    end
  end

  def selectContext(cnil(), selector) do
    raise "Context not found for selector : #{inspect(selector)}"
  end

  def function(f) do
  #defmacro function(f) do
    #quote location: :keep do
      #Op.op(fn _m, ctx, x -> under(ctx, unquote(f).(x)) end)
      Op.op(fn _m, ctx, x -> under(ctx, f.(x)) end)
    #end
  end

  def value(x) do
    function(fn {} -> pure(x) end)
  end

  @doc """
  operation :: (a -> (b -> Eff e ans) -> Eff e ans) -> Op a b e ans
  """
  #defmacro operation(f) do
  def operation(f) do
    #quote do
      Op.op(fn m, ctx, x ->
        Ctl.yield(m, fn ctlk ->
          k = fn y ->
            eff(fn ctx_ ->
              guard(ctx, ctx_, ctlk, y)
            end)
          end
          #under(ctx, unquote(f).(x, k))
          under(ctx, f.(x, k))
        end)
      end)
    #end
  end

  defmacro except(f) do
    quote do
      Op.op(fn m, ctx, x -> Ctl.yield(m, fn _ctlk -> under(ctx, unquote(f).(x)) end) end)
    end
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

  def mask(eff), do: eff(fn ccons(_m, _h, _t, ctx) ->
    under(ctx, eff)
  end)

  def handlerRet(ret, handler, action) do
    handler(handler, map(action, ret))
  end

  def handlerRetEff(ret, h, action) do
    handler(h, map(action, ret))
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
      transform = &ccons(m_, h_, g_, &1)
      Ctl.prompt(fn m -> m Ctl do
        x <- under(ccons(m, h, transform, ctx_), action)
        ef = ret.(x)
        under(ctx, ef)
      end end)
    end
  end
end
