defmodule Infer.Guard do
  import Circe

  alias DataTypes, as: DT
  require DT

  def type_constraints_from_guard(guard) do
    case guard do
      ~m/is_binary(#{{_, _, ctxt} = var})/ when is_atom(ctxt) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        %{var => DT.type(:binary)}

      ~m/is_list(#{{_, _, ctxt} = var})/ when is_atom(ctxt) ->
        var = Macro.update_meta(var, &Keyword.delete(&1, :line))
        %{var => DT.hkt(:list, [DT.unknown()])}

      guard ->
        IO.inspect(guard, label: "guard")
        %{}
    end
  end

  def merge_guards_constraints(constraintss) do
    Enum.reduce(constraintss, %{}, &Map.merge(&1, &2, fn k, l, r -> raise("unexpected guard conflict: k = #{inspect(k)}, l = #{inspect(l)}, r = #{inspect(r)}") end))
  end

  def constraints(guards) do
    guards
    |> Enum.map(&type_constraints_from_guard/1)
    |> Infer.Guard.merge_guards_constraints()
  end
end
