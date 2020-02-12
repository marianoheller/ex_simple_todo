defmodule Calculator do
  def start do
    spawn(fn ->
      current_value = 0
      loop(current_value)
    end)
  end

  def sum(server_pid, input) do
    send(server_pid, {:sum, input})
  end

  def sub(server_pid, input) do
    send(server_pid, {:sub, input})
  end

  def mul(server_pid, input) do
    send(server_pid, {:mul, input})
  end

  def div(server_pid, input) do
    send(server_pid, {:div, input})
  end

  def value(server_pid) do
    send(server_pid, {:value, self()})

    receive do
      {:response, value} ->
        value
    end
  end

  defp loop(current_value) do
    new_value =
      receive do
        {:value, caller} ->
          send(caller, {:response, current_value})
          current_value

        {:add, value} ->
          current_value + value

        {:sub, value} ->
          current_value - value

        {:mul, value} ->
          current_value * value

        {:div, value} ->
          current_value / value

        invalid_request ->
          IO.puts("invalid request #{inspect(invalid_request)}")
          current_value
      end

    loop(new_value)
  end
end
