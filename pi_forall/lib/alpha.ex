defprotocol Alpha.Protocol do
  def aeq(a, b, context)
end

defmodule Alpha.Ctx do
  @enforce_keys [:mode, :level]
  defstruct @enforce_keys
end

defmodule Alpha do
  def aeq(a, b, ctx) do
    __MODULE__.Protocol.aeq(a, b, ctx)
  end

  def initial_ctx, do: %Alpha.Ctx{mode: :term, level: 0}

  def pattern_ctx(%Alpha.Ctx{} = ctx), do: %Alpha.Ctx{ctx | mode: :pat}

  def term_ctx(%Alpha.Ctx{} = ctx), do: %Alpha.Ctx{ctx | mode: :term}

  def is_term_ctx(%Alpha.Ctx{mode: :term}), do: true
  def is_term_ctx(%Alpha.Ctx{}), do: false

  def is_pat_ctx(%Alpha.Ctx{mode: :pat}), do: true
  def is_pat_ctx(%Alpha.Ctx{}), do: false

  def incr_level_ctx(%Alpha.Ctx{level: l} = ctx), do: %Alpha.Ctx{ctx | level: l + 1}
  def decr_level_ctx(%Alpha.Ctx{level: l} = ctx), do: %Alpha.Ctx{ctx | level: l - 1}

  def is_zero_level_ctx(%Alpha.Ctx{level: l}), do: l == 0
end

defimpl Alpha.Protocol, for: Types.Name do
  def aeq(namel, namer, ctx) do
    if Alpha.is_term_ctx(ctx) do
      namel == namer
    else
      true
    end
  end
end

defimpl Alpha.Protocol, for: Types.Bind do
  import Types

  def aeq(bind(pl, tl), bind(pr, tr), ctx) do
    @protocol.aeq(pl, pr, ctx) and @protocol.aeq(tl, tr, ctx)
  end
end
