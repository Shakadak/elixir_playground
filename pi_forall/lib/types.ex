defmodule Types do
  import Data

  # type tname = Unbound.name(term)

  # type type = term

  data Bind do
    bind(pattern, term)
  end

  # name
  data Name do
    free_name(name, integer)
    # binding level + pattern_index
    bound_name(integer, integer)
  end
end

# defimpl Walk.Protocol, for: Types.Term do
#   import Types
# 
#   def gfoldl(ty_type(), _k, z), do: z.(ty_type())
#   def gfoldl((var tname), k, z), do: z.(&var &1) |> k.(tname)
#   def gfoldl((lam tname, term), k, z), do: z.(fn x -> fn y -> (lam x, y) end end) |> k.(tname) |> k.(term)
#   def gfoldl((app term1, term), k, z), do: z.(fn x -> fn y -> (app x, y) end end) |> k.(term1) |> k.(term)
#   def gfoldl(ty_pi(type, bind), k, z), do: z.(fn x -> fn y -> ty_pi(x, y) end end) |> k.(type) |> k.(bind)
#   def gfoldl(ann(term, type), k, z), do: z.(fn x -> fn y -> ann(x, y) end end) |> k.(term) |> k.(type)
# end
# 
# defimpl Alpha.Protocol, for: Types.Term do
#   import Types
# 
#   def aeq(l, r, ctx) do
#     case {l, r} do
#       {ty_type(), ty_type()} -> true
# 
#       {(var tnamel), (var tnamer)} -> aeq tnamel, tnamer, ctx
# 
#       {(lam _tname, term), (lam _tname2, term2)} -> aeq term, term2, ctx
# 
#       {(app terma, terma2), (app termb, termb2)} ->
#         (aeq terma, termb, ctx) and (aeq terma2, termb2, ctx)
# 
#       {(ty_pi typel, bindl), (ty_pi typer, bindr)} ->
#         (aeq typel, typer, ctx) and (@protocol.aeq bindl, bindr, ctx)
# 
#       {(ann terml, typel), (ann termr, typer)} ->
#         (aeq terml, termr, ctx) and (aeq typel, typer, ctx)
# 
#       _ -> false
#     end
#   end
# end
# 
# defimpl Subst.Protocol, for: Types.Term do
#   use Subst.Protocol
# 
#   import Types
# 
#   @spec is_var(any) :: {:some, any} | :none
#   def is_var(var(x)), do: {:some, {:subst_name, x}}
#   def is_var(_), do: :none
# end
