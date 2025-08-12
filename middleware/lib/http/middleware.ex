defmodule Http.Middleware do
  @moduledoc """
  Documentation for `Middleware`.
  """

  alias Http.Request
  alias Http.Response

  alias __MODULE__

  @type resp_m(val) :: {:ok, Response.t(val)} | {:error, Exception.t()}

  defmodule Runner do
    alias Http.Middleware

    @enforce_keys [:runner]
    defstruct @enforce_keys

    @type t(a, b) :: %__MODULE__{
            runner: (Request.t(a) -> Middleware.resp_m(b))
          }
  end

  @enforce_keys [:middleware]
  defstruct @enforce_keys

  @type t(
          # This is the request type that the initial runner expect
          req1,
          # This is the response type that the initial runner outputs
          resp1,
          # This is the request type that the new runner will expect
          req2,
          # This is the response type that the new runner will output
          resp2
        ) :: %__MODULE__{
          middleware: (Runner.t(req1, resp1) -> Runner.t(req2, resp2))
        }

  @typedoc """
  This is a middleware that won't change the input or the output of the runner.

  It will do operations that don't need a different input, or modify the output of
  the inner runner.
  """
  @type endo_t(req, resp) :: t(req, resp, req, resp)

  @spec exec(t(req1, resp1, req2, resp2), Runner.t(req1, resp1)) :: resp_m(resp2)
        when req1: var, resp1: var, req2: any, resp2: var
  def exec(%Middleware{} = mw, %Runner{} = runner) do
    run(mw, Request.default(), runner)
  end

  def mwl +++ mwr, do: compose(mwl, mwr)

  @spec run(t(req1, resp1, req2, resp2), Request.t(req2), Runner.t(req1, resp1)) ::
          resp_m(resp2)
        when req1: var, resp1: var, req2: var, resp2: var
  def run(%Middleware{middleware: pipeline}, %Request{} = req, %Runner{} = runner) do
    %Runner{runner: final_runner} = pipeline.(runner)
    final_runner.(req)
  end

  def identity do
    %Middleware{middleware: &Function.identity/1}
  end

  # def mapRequest(%Middleware{middleware: runner}, f) do
  #  %Middleware{middleware: fn %Runner{} = inner_runner ->
  #    &runner.(f.(&1))
  #  end}
  # end

  @spec around(callback) :: endo_t(req, resp)
        when callback: (Request.t(req), action -> resp_m(resp)),
             action: (-> resp_m(resp)),
             req: var,
             resp: var

  def around(f) do
    %Middleware{
      middleware: fn %Runner{runner: next} ->
        %Runner{
          runner: fn %Request{} = req ->
            f.(req, fn -> next.(req) end)
          end
        }
      end
    }
  end

  def on_request(f) do
    %Middleware{
      middleware: fn %Runner{runner: next} ->
        %Runner{
          runner: fn %Request{} = req ->
            next.(f.(req))
          end
        }
      end
    }
  end

  def on_response(f) do
    %Middleware{
      middleware: fn %Runner{runner: next} ->
        %Runner{
          runner: fn %Request{} = req ->
            f.(next.(req))
          end
        }
      end
    }
  end

  @spec map_shallow_request(t(req1, resp1, req2, resp2), (Request.t(req0) -> Request.t(req1))) ::
          t(req0, resp1, req2, resp2)
        when req1: var, resp1: var, req2: var, resp2: var, req0: var
  def map_shallow_request(%Middleware{} = mw, f) do
    dimap_middleware(mw, &map_runner_request(&1, f), &Function.identity/1)
  end

  @spec map_deep_request(t(req1, resp1, req2, resp2), (Request.t(req3) -> Request.t(req2))) ::
          t(req1, resp1, req3, resp2)
        when req1: var, resp1: var, req2: var, resp2: var, req3: var
  def map_deep_request(%Middleware{} = mw, f) do
    dimap_middleware(mw, &Function.identity/1, &map_runner_request(&1, f))
  end

  @spec map_deep_response(t(req1, resp1, req2, resp2), (resp_m(resp1) -> resp_m(resp0))) ::
          t(req1, resp0, req2, resp2)
        when req1: var, resp1: var, req2: var, resp2: var, resp0: var
  def map_deep_response(%Middleware{} = mw, f) do
    dimap_middleware(mw, &map_runner_response(&1, f), &Function.identity/1)
  end

  @spec map_deep_response(t(req1, resp1, req2, resp2), (resp_m(resp2) -> resp_m(resp3))) ::
          t(req1, resp1, req2, resp3)
        when req1: var, resp1: var, req2: var, resp2: var, resp3: var
  def map_shallow_response(%Middleware{} = mw, f) do
    dimap_middleware(mw, &Function.identity/1, &map_runner_response(&1, f))
  end

  @spec dimap_middleware(
          t(req1, resp1, req2, resp2),
          (Runner.t(req0, resp0) -> Runner.t(req1, resp1)),
          (Runner.t(req2, resp2) -> Runner.t(req3, resp3))
        ) ::
          t(req0, resp0, req3, resp3)
        when req1: var,
             resp1: var,
             req2: var,
             resp2: var,
             req0: var,
             resp0: var,
             req3: var,
             resp3: var
  def dimap_middleware(%Middleware{middleware: middleware}, f_in, f_out) do
    %Middleware{
      middleware:
        &(%Runner{} = f_out.(%Runner{} = middleware.(%Runner{} = f_in.(%Runner{} = &1))))
    }
  end

  def map_runner_request(%Runner{} = runner, f) do
    dimap_runner(runner, f, &Function.identity/1)
  end

  def map_runner_response(%Runner{runner: runner}, f) do
    dimap_runner(runner, &Function.identity/1, f)
  end

  def dimap_runner(%Runner{runner: runner}, f_req, f_resp) do
    %Runner{runner: &f_resp.(runner.(%Request{} = f_req.(%Request{} = &1)))}
  end

  def compose(%Middleware{middleware: ml}, %Middleware{middleware: mr}) do
    %Middleware{
      middleware: fn %Runner{} = runner ->
        ml.(mr.(runner))
      end
    }
  end

  def compose_many(xs) do
    List.foldr(xs, identity(), &compose(&1, &2))
  end
end
