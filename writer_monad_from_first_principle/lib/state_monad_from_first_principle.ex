defmodule StateMonadFromFirstPrinciple do
  def reverse_with_count(fun_count, list) do
    {fun_count + 1, Enum.reverse(list)}
  end

  def append_reversed_with_count(fun_count, list1, list2) do
    {fun_count1, revlist1} = reverse_with_count(fun_count, list1)
    {fun_count2, revlist2} = reverse_with_count(fun_count1, list2)
    {fun_count2 + 1, revlist1 ++ revlist2}
  end

  def append3_reversed_with_count(func_count, list1, list2, list3) do
    {fun_count1, revlist1} = reverse_with_count(fun_count, list1)
    {fun_count2, revlist2} = reverse_with_count(fun_count1, list2)
    {fun_count3, revlist3} = reverse_with_count(fun_count2, list3)
    {fun_count3 + 1, revlist1 ++ revlist2 ++ revlist3}
end
