defmodule MiddlewareTest do
  use ExUnit.Case
  doctest Middleware

  test "greets the world" do
    assert Middleware.hello() == :world
  end
end
