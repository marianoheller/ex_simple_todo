defmodule SimpleTodoTest do
  use ExUnit.Case
  doctest SimpleTodo

  test "greets the world" do
    assert SimpleTodo.hello() == :world
  end
end
