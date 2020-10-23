require Monad.Writer
Monad.Writer.functor(module: Monad.Writer.List, mappend: Kernel.++, mempty: [])
Monad.Writer.functor(module: Monad.Writer.String, mappend: Kernel.<>, mempty: "")

defmodule WriterMonadFromFirstPrinciple do
  @moduledoc """
  Documentation for `WriterMonadFromFirstPrinciple`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> WriterMonadFromFirstPrinciple.hello()
      :world

  """

  def add_two(x), do: {["adding 2..."], x + 2}

  def augment_and_stringify(x, y) do
    {xLog, x2} = add_two(x)
    {yLog, y2} = add_two(y)
    {["augmenting..."] ++ xLog ++ yLog ++ ["stringifying..."], to_string(x2 + y2)}
  end

  def m_add_two(x) do
    import Monad.Logger
    m do
      log "adding 2..."
      pure x + 2
    end
  end

  def m_augment_and_stringify(x, y) do
    import Monad.Logger
    m do
      log "augmenting..."
      x2 <- m_add_two(x)
      y2 <- m_add_two(y)
      log "stringifying..."
      pure to_string(x2 + y2)
    end
  end

  def m_basic_chain(x) do
    import Monad.Logger
    m do
      log "banana"
      pure x
    end
  end

  def ml_basic_chain(x) do
    import Monad.Writer.List
    m do
      tell ["banana"]
      pure x
    end
  end

  def ml_augment_and_stringify(x, y) do
    import Monad.Writer.List
    m do
      tell ["augmenting..."]
      x2 <- m_add_two(x)
      y2 <- m_add_two(y)
      tell ["stringifying..."]
      pure to_string(x2 + y2)
    end
  end

  def ms_basic_chain(x) do
    import Monad.Writer.String
    m do
      tell "banana"
      pure x
    end
  end

  def ms_add_two(x) do
    import Monad.Writer.String
    m do
      tell "adding 2..."
      pure x + 2
    end
  end

  def ms_augment_and_stringify(x, y) do
    import Monad.Writer.String
    m do
      tell "augmenting..."
      x2 <- ms_add_two(x)
      y2 <- ms_add_two(y)
      tell "stringifying..."
      pure to_string(x2 + y2)
    end
  end
end
