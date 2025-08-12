defmodule Http.Middleware.Example do
  alias Http.Middleware
  alias Http.Request

  alias Middleware.Runner

  def step_n(n) do
    %Middleware{middleware: &step_n(n, &1)}
  end

  def step_n(n, %Runner{runner: runner}) do
    fn %Request{} = req ->
      IO.puts("#{n} pre")
      resp = runner.(req)
      IO.puts("#{n} post")
      resp
    end
    |> then(&%Runner{runner: &1})
  end

  def step_n2(n) do
    step_pre(n)
    |> Middleware.compose(step_post(n))
  end

  def step_pre(n), do: %Middleware{middleware: &step_pre(n, &1)}

  def step_pre(n, %Runner{runner: runner}) do
    fn %Request{} = req ->
      IO.puts("#{n} pre")
      runner.(req)
    end
    |> then(&%Runner{runner: &1})
  end

  def step_post(n), do: %Middleware{middleware: &step_post(n, &1)}

  def step_post(n, %Runner{runner: runner}) do
    fn %Request{} = req ->
      resp = runner.(req)
      IO.puts("#{n} post")
      resp
    end
    |> then(&%Runner{runner: &1})
  end
end
