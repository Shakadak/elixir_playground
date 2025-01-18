defmodule Ast.Check do
  alias ComputationExpression, as: CE
  require CE

  # alias Wrapped.ResultState
  # alias Base.Result
  # require Result

  alias   DataTypes, as: DT
  require DT

  import  Ast.Core, only: [
    # app: 2,
    # clause: 2,
    # gclause: 3,
    # lam: 2,
    # # let: 2,
    lit: 1,
    # # non_rec: 2,
    var: 1,
  ]

  #import  Ast.Core.Typed, only: [
  #  app_t: 3,
  #  case_t: 3,
  #  clause_t: 4,
  #  lam_t: 3,
  #  let_t: 3,
  #  lit_t: 2,
  #  non_rec_t: 3,
  #  var_t: 2,
  #]

  def pattern(ast, expected_type) do
    CE.compute Workflow.ResultState do
      match {ast, expected_type} do
        {lit(x), DT.type(:integer)} when is_integer(x) -> pure {}
        {var(:_), _t} -> pure {}
        {var(identifier), type} ->
          do! Ast.put_var_type(identifier, type)
          pure {}
      end
    end
  end
end
