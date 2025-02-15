defmodule Eff do
  import Bind

  import Context.{CCons, CNil}
  require Op

  require Ctl

  defmacro __using__([]) do
    quote do
      import Bind
      import Eff
      import Context.CCons
      require Op
      require Ctl
    end
  end

  defmacro eff(f) do
    f
  end

  require Eff.Internal

  @doc """
  under :: Context e -> Eff e a -> Ctl a
  """
  defmacro under(ctx, eff) do
    #IO.inspect(__CALLER__, label: "under.__CALLER__")
    # _ = IO.puts(Macro.to_string(eff))
    #pure_branch = Eff.Internal.convert_fn(ctx, Macro.expand(eff, __CALLER__))
    pure_branch = Eff.Internal.convert_fn(ctx, eff)

    case pure_branch do
      {:raw, ast} -> ast
      {:fn, ast} -> quote(do: unquote(ast).(unquote(ctx)))
    end
  end
  #def under(ctx, eff(eff)), do: eff.(ctx)

  defmacro pure(x) do
    quote do
      eff(fn _ctx ->
        Ctl.pure(unquote(x))
      end)
    end
  end

  defmacro bind(eff, f) do
    ctl = Macro.unique_var(:ctl, __MODULE__)

    next =
      Eff.Internal.convert_fn(ctl, f)
      |> case do
        {:raw, ast} -> ast
        {:fn, _ast} -> quote do unquote(f).(unquote(ctl)) end
      end

    quote generated: true do
      eff(fn ctx ->
        m Ctl do
          unquote(ctl) <- under(ctx, unquote(eff))
          under(ctx, unquote(next))
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

  def map(m1, f) do
    bind(m1, fn a -> pure(f.(a)) end)
  end

  def runEff(eff(eff)) do
    ctl = eff.(cnil())
    Ctl.runCtl(ctl)
  end

  defmacro perform(selectOp, x) do
    quote do
      eff(fn ctx -> unquote(selectOp).(ctx, unquote(x)) end)
    end
  end

  #def perform(selectOp, x) when is_function(selectOp, 2) do
  #  eff(fn ctx -> selectOp.(ctx, x) end)
  #end

  #def perform(%impl{} = selectOp, x) do
  #  # withSubcontext(fn ccons(m, h, t, ctx_) ->
  #  #   new_ctx = t.(ctx_)
  #  #   impl.runOp(selectOp, h, m, new_ctx, x)
  #  # end, selectOp)
  #  eff(fn ctx ->
  #    ccons(m, h, t, ctx_) = selectContext(ctx, selectOp)
  #    impl.runOp(selectOp, h, m, t.(ctx_), x)
  #  end)
  #end

  # def select_and_run_context(ccons(m, h, t, sub_ctx), selector, x) when is_function(selector, 4) do
  #   case selector.(h, m, t, sub_ctx) do
  #     false -> select_and_run_context(sub_ctx, selector, x)
  #     op -> op.(h, m, t.(sub_ctx), x)
  #   end
  # end

  #def selectContext(ccons(_m, h, _t, sub_ctx) = ctx, %impl{} = selector) do
  #  case impl.appropriate?(selector, h) do
  #    false -> selectContext(sub_ctx, selector)
  #    true -> ctx
  #  end
  #end

  # def selectContext(cnil(), selector) do
  #   raise "Context not found for selector : #{inspect(selector)}"
  # end

  #def function(f) do
  defmacro function(f) do
    quote location: :keep do
      Op.op(fn _m, ctx, x -> under(ctx, unquote(f).(x)) end)
      #Op.op(fn _m, ctx, x -> under(ctx, f.(x)) end)
    end
  end

  def value(x) do
    function(fn {} -> pure(x) end)
  end

  @doc """
  operation :: (a -> (b -> Eff e ans) -> Eff e ans) -> Op a b e ans
  """
  #def operation(f) do
  defmacro operation(f) do
    quote location: :keep do
      Op.op(fn m, ctx, x ->
        Ctl.yield(m, fn ctlk ->
          k = fn y ->
            eff(fn ctx_ ->
              guard(ctx, ctx_, ctlk, y)
            end)
          end
          under(ctx, unquote(f).(x, k))
          #under(ctx, f.(x, k))
        end)
      end)
    end
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

  @doc false
  def handlerRetEff(ret, h, action) do
    handler(h, map(action, &mask(ret.(&1))))
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
