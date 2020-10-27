defmodule ReadeMonadFromFirstPrinciple do
  def ab_config(e, l) do
    %{dont_use_letter_E: e, dont_user_letter_L: l}
  end

  def to_upper_str(cfg, str) do
    filters = [
      (if cfg.dont_use_letter_E, do: fn x -> x != ?E end, else: fn _ -> true end),
      (if cfg.dont_use_letter_L, do: fn x -> x != ?L end, else: fn _ -> true end),
    ]
    passes_filters = fn c -> Enum.all?(filters, fn f -> f.(c) end) end
    String.upcase(str)
    |> String.to_charlist()
    |> Enum.filter(passes_filters)
    |> to_string()
  end

  def welcome_message(cfg, motd, username) do
    "Welcome, #{to_upper_str(cfg, username)}! Message of the day: #{to_upper_str(cfg, motd)}"
  end

  def full_name(cfg, first_name, nickname, last_name) do
    ~s(#{to_upper_str(cfg, first_name)} "#{to_upper_str(cfg, nickname)}" #{to_upper_str(cfg, last_name)})
  end

  def m_to_upper_str(str) do
    Monad.Reader.new(fn cfg ->
      filters = [
        (if cfg.dont_use_letter_E, do: fn x -> x != ?E end, else: fn _ -> true end),
        (if cfg.dont_use_letter_L, do: fn x -> x != ?L end, else: fn _ -> true end),
      ]
      passes_filters = fn c -> Enum.all?(filters, fn f -> f.(c) end) end
      String.upcase(str)
      |> String.to_charlist()
      |> Enum.filter(passes_filters)
      |> to_string()
    end)
  end

  def m_welcome_message(motd, username) do
    m_to_upper_str(username)
    |> Monad.Reader.bind(fn username ->
      m_to_upper_str(motd)
      |> Monad.Reader.bind(fn motd ->
        Monad.Reader.new(fn _ -> "Welcome, #{username}! Message of the day: #{motd}" end)
      end)
    end)
  end

  def m_full_name(first_name, nickname, last_name) do
    m_to_upper_str(first_name)
    |> Monad.Reader.bind(fn first_name ->
      m_to_upper_str(nickname)
      |> Monad.Reader.bind(fn nickname ->
        m_to_upper_str(last_name)
        |> Monad.Reader.bind(fn last_name ->
          Monad.Reader.new(fn _ -> ~s(#{first_name} "#{nickname}" #{last_name}) end)
        end)
      end)
    end)
  end

  def m2_to_upper_str(str) do
    import Monad
    import Monad.Reader

    m Monad.Reader do
      cfg <- ask()
      filters = [
        (if cfg.dont_use_letter_E, do: fn x -> x != ?E end, else: fn _ -> true end),
        (if cfg.dont_use_letter_L, do: fn x -> x != ?L end, else: fn _ -> true end),
      ]
      passes_filters = fn c -> Enum.all?(filters, fn f -> f.(c) end) end
      String.upcase(str)
      |> String.to_charlist()
      |> Enum.filter(passes_filters)
      |> to_string()
      |> pure()
    end
  end

  def m2_welcome_message(motd, username) do
    import Monad
    import Monad.Reader

    m Monad.Reader do
      username <- m2_to_upper_str(username)
      motd <- m2_to_upper_str(motd)
      pure "Welcome, #{username}! Message of the day: #{motd}"
    end
  end

  def m2_full_name(first_name, nickname, last_name) do
    import Monad
    import Monad.Reader

    m Monad.Reader do
      first_name <- m2_to_upper_str(first_name)
      nickname <- m2_to_upper_str(nickname)
      last_name <- m2_to_upper_str(last_name)
      pure ~s(#{first_name} "#{nickname}" #{last_name})
    end
  end
end
