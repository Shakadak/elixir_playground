defprotocol Solver do
  @type constraint(_solver) :: any
  @type term(_solver) :: any
  @type solver(_a) :: t
  @type solver :: t

  @spec newvar(t) :: solver(term(solver))
  def newvar(solver)

  @spec add(t, constraint(solver)) :: solver(boolean)
  def add(solver, constraint)

  @spec run(t, solver(a)) :: a when a: var
  def run(solver, solver)
end
