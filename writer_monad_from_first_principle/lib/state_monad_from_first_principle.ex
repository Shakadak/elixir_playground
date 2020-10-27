defmodule StateMonadFromFirstPrinciple do
  def reverse_with_count(fun_count, list) do
    {fun_count + 1, Enum.reverse(list)}
  end

  def append_reversed_with_count(fun_count, list1, list2) do
    {fun_count1, revlist1} = reverse_with_count(fun_count, list1)
    {fun_count2, revlist2} = reverse_with_count(fun_count1, list2)
    {fun_count2 + 1, revlist1 ++ revlist2}
  end

  def append3_reversed_with_count(fun_count, list1, list2, list3) do
    {fun_count1, revlist1} = reverse_with_count(fun_count, list1)
    {fun_count2, revlist2} = reverse_with_count(fun_count1, list2)
    {fun_count3, revlist3} = reverse_with_count(fun_count2, list3)
    {fun_count3 + 1, revlist1 ++ revlist2 ++ revlist3}
  end

  def m_reverse_with_count(list) do
    Monad.State.new(fn s -> {s + 1, Enum.reverse(list)} end)
  end

  def m_append_reversed_with_count(list1, list2) do
    m_reverse_with_count(list1)
    |> Monad.State.bind(fn revlist1 ->
      m_reverse_with_count(list2)
      |> Monad.State.bind(fn revlist2 ->
        Monad.State.new(fn s -> {s + 1, revlist1 ++ revlist2} end)
      end)
    end)
  end

  def m_append3_reversed_with_count(list1, list2, list3) do
    m_reverse_with_count(list1)
    |> Monad.State.bind(fn revlist1 ->
      m_reverse_with_count(list2)
      |> Monad.State.bind(fn  revlist2 ->
        m_reverse_with_count(list3)
        |> Monad.State.bind(fn revlist3 ->
          Monad.State.new(fn s -> {s + 1, revlist1 ++ revlist2 ++ revlist3} end)
        end)
      end)
    end)
  end

  def m3_reverse_with_count(list) do
    import Monad
    import Monad.State

    m Monad.State do
      modify(fn s -> s + 1 end)
      pure Enum.reverse(list)
    end
  end

  def m3_append_reversed_with_count(list1, list2) do
    import Monad
    import Monad.State

    m Monad.State do
      revlist1 <- m3_reverse_with_count(list1)
      revlist2 <- m3_reverse_with_count(list2)
      modify fn s -> s + 1 end
      pure revlist1 ++ revlist2
    end
  end

  def m3_append3_reversed_with_count(list1, list2, list3) do
    import Monad
    import Monad.State

    m Monad.State do
      revlist1 <- m3_reverse_with_count(list1)
      revlist2 <- m3_reverse_with_count(list2)
      revlist3 <- m3_reverse_with_count(list3)
      modify fn s -> s + 1 end
      pure revlist1 ++ revlist2 ++ revlist3
    end
  end
end
