defmodule Test.Utils do
  alias   DataTypes, as: DT
  require DT

  def a, do: DT.rigid_variable(:a)

  def id, do: DT.fun([a()], a())

  def int, do: DT.type(:integer)

  def add_op, do: DT.fun([int(), int()], int())

  def atom, do: DT.type(:atom)

  def check(ast, expected, vars) do
    env = put_in(Ast.empty_state(), [Ast.Access.vars()], vars)

    Wrapped.ResultState.evalStateT(Ast.check(ast, expected), env)
  end
end
