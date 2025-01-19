defprotocol Subst.Protocol do
  @spec is_var(any) :: {:some, any} | :none
  def is_var(a)

  def subst(_name, _substitute, _term)

  defmacro __using__([] = _opts) do
    quote do
      def is_var(_), do: :none

      def subst(name, substitute, term) do
      end

      defoverridable Subst.Protocol
    end
  end
end

# defmodule Subst do
#   @spec is_var(any) :: {:some, any} | :none
#   def is_var(x), do: __MODULE__.Protocol.is_var(x)
# 
#   @doc """
#   Substitute `name` for `substitute` in `term`
#   """
#   def subst(name, substitute, term) do
#     if is_free(name) do
#       Syntax.prewalk(term, fn term ->
#         case is_var(term) do
#           {:some, {:subst_name, m}} ->
#             if m == name do
#               substitute
#             else
#               term
#             end
# 
#           :none ->
#             term
#         end
#       end)
#     else
#       raise "Cannot substitute for bound variable #{inspect(name)}"
#     end
#   end
# 
#   def is_free({:name, _, _}), do: true
#   def is_free({:bound, _, _, _}), do: false
# end
