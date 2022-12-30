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
end
