defmodule Data.Validation do
  def failure(x) do {:failure, x} end
  def success(x) do {:success, x} end

  def failure?({:failure, _}) do true end
  def failure?(_) do false end

  def success?({:success, _}) do true end
  def success?(_) do false end

  defmacro is_failure(x) do quote do (is_tuple(unquote(x)) and tuple_size(unquote(x)) == 2 and elem(unquote(x), 0) == :failure) end end
  defmacro is_success(x) do quote do (is_tuple(unquote(x)) and tuple_size(unquote(x)) == 2 and elem(unquote(x), 0) == :success) end end

  def from_failure({:failure, x}, _) do x end
  def from_failure(_, x) do x end

  def from_success({:success, x}, _) do x end
  def from_success(_, x) do x end

  def map({:failure, _} = x, _) do x end
  def map({:success, x}, f) when is_function(f, 1) do {:success, f.(x)} end
  def map({:success, x}, {f, a}) when is_function(f) and is_list(a) do {:success, apply(f, [x | a])} end
  def map({:success, x}, {m, f, a}) when is_list(a) do {:success, apply(m, f, [x | a])} end

  def join({:failure, _} = x) do x end
  def join({:success, {:failure, _} = x}) do x end
  def join({:success, {:success, _} = x}) do x end

  def bind({:failure, _} = x, _) do x end
  def bind({:success, x}, f) when is_function(f, 1) do f.(x) end
  def bind({:success, x}, {f, a}) when is_function(f) and is_list(a) do apply(f, [x | a]) end
  def bind({:success, x}, {m, f, a}) when is_list(a) do apply(m, f, [x | a]) end

  def nil_to_validation(nil, x) do {:failure, x} end
  def nil_to_validation(x, _) do {:success, x} end
end
