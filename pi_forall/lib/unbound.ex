defmodule Unbound do
  import Data

  data Bind do
    bind(name, term)
  end

  data SubstName do
    subst_name(term)
  end

  data Name do
    name(term)
  end

  defmacro raise_unimplemented do
    quote do
      case :rand.uniform(1) do
        1 ->
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: "#{inspect(__ENV__.module)}.#{inspect(__ENV__.function)} unimplemented"
        _ -> {}
      end
    end
  end

  def aeq(_l, _r) do
    raise_unimplemented()
  end

  def to_list_of(_, _) do
    raise_unimplemented()
  end

  def fv do
    raise_unimplemented()
  end

  def subst(_name, _substitute, _term) do
    raise_unimplemented()
  end

  def instantiate(_bnd, _a) do
    raise_unimplemented()
  end

  def unbind(_binding) do
    raise_unimplemented()
  end

  def unbind2(_binding1, _binding2) do
    raise_unimplemented()
  end

  def gaeq(_ctx, _a, _b) do
    raise_unimplemented()
  end

  def string2name(_n) do
    raise_unimplemented()
  end
end
