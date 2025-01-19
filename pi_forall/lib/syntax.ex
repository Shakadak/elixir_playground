defmodule Syntax do
  import Data

  import Maybe
  import Parser

  require Unbound

  data Term do
    # type of types, concretely `Type`
    ty_type
    # variable `x`
    var(tname)
    # abstraction `\x. a`
    lam(bind(tname, term))
    # application `a b`
    app(term, term)
    # function type `(x : A) -> B`
    ty_pi(type, bind(tname, type))
    # annotated terms `(a : A)`
    ann(term, type)
    # marked source position, for error messages
    pos(source_pos, term)
    # an axiom 'TRUSTME', inhabits all types
    trust_me
    # a directive to the type checker to print out the current context
    print_me
    # let expression, introduces a new (non-recursive) definition in the ctx
    # `let x = a in b`
    let(term, bind(tname, term))
    # the type with a single inhabitant, called `Unit`
    ty_unit
    # the inhabitant of `Unit`, written `()`
    lit_unit
    # the type with two inhabitants (homework) `Bool`
    ty_bool
    # `True` and `False`
    lit_bool(boolean)
    # `if a then b1 else b2` expression for eliminating booleans
    if_(term, term, term)
    # Sigma-type (homework), written `{x : A | B}`
    ty_sigma(term, bind(tname, term))
    # introduction form for Sigma-types `(a, b)`
    prod(term, term)
    # elimination form for Sigma-types `let (x, y) = a in b`
    let_pair(term, bind({tname, tname}, term))
  end

  data TypeDecl do
    type_decl(name, type)
  end

  data Entry do
    # Declaration for the type of a term 'x : A'
    decl(type_decl)
    # The definition of a particular name 'x = a'
    # must already have a type declaration in scope
    def_(tname, term)
  end

  def mk_decl(n, ty), do: decl(type_decl(n, ty))

  # Remove source positions and type annotations from the top level of a term
  def strip(pos(_, tm)), do: strip(tm)
  def strip(ann(tm, _)), do: strip(tm)
  def strip(tm), do: tm

  # Partial inverse of Pos
  def un_pos(pos(p, _)), do: just(p)
  def un_pos(_), do: nothing()

  # Tries to fing a Pos inside a term, otherwise just gives up.
  def un_pos_flaky(t) do
    from_maybe(new_pos("unkown location", 0, 0), un_pos(t))
  end

  ##############

  # Unbound library

  ##############

  # Determine when two terms are alpha-equivalent
  def aeq(l, r), do: Unbound.aeq(l, r)

  # Calculate the free variables of a term
  def fv(term), do: Unbound.to_list_of(Unbound.fv, term)

  # `subst x b a` means to repalace `x` with `b` in `a`
  # i.e. a [ b / x ]
  def subst(tname, substitute, term), do: Unbound.subst(tname, substitute, term)

  # in a binder `x.a` replace `x` with `b`
  def instanciate(bnd, a), do: Unbound.instantiate(bnd, a)

  # in binders `x.a` replace `x` with a fresh name
  def unbind(b), do: Unbound.unbind(b)

  # in binders `x.a1` and `x.a2` replace `x` with a fresh name in both terms
  def unbind2(b1, b2) do
    Unbound.unbind2(b1, b2)
    |> Unbound.Fresh.bind(fn o ->
      case o do
        just({x, t, _, u}) -> Unbound.Fresh.pure({x, t, u})
      end
    end)
  end

  ##############

  # Alpha class instances

  ##############

  def aeq(ctx, a, b) do
    Unbound.gaeq(ctx, strip(a), strip(b))
  end

  def x_name, do: Unbound.string2name("x")

  def y_name, do: Unbound.string2name("y")

  def idx, do: lam(Unbound.bind(x_name(), var(x_name())))

  def idy, do: lam(Unbound.bind(y_name(), var(y_name())))

  ##############

  # Substitution

  ##############

  def isvar(var(x)), do: just(Unbound.subst_name(x))
  def isvar(_), do: nothing()

  # '(y : x) -> y'
  def pi1, do: ty_pi(var(x_name()), Unbound.bind(y_name(), var(y_name())))

  # '(y : Bool) -> y
  def pi2, do: ty_pi(ty_bool(), Unbound.bind(y_name(), var(y_name())))

  # def prewalk(data, fun) do
  #   data = fun.(data)

  #   case data do
  #     ty_type() ->
  #       data

  #     var(_tname) ->
  #       data

  #     lam(tname, term) ->
  #       lam(tname, prewalk(term, fun))

  #     app(term, term2) ->
  #       app(prewalk(term, fun), prewalk(term2, fun))

  #     ty_pi(type, bind(tname, type2)) ->
  #       ty_pi(prewalk(type, fun), bind(tname, prewalk(type2, fun)))

  #     ann(term, type) ->
  #       ann(prewalk(term, fun), prewalk(type, fun))
  #   end
  # end
end
