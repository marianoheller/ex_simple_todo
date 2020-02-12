defmodule TodoServer do
  def start do
    spawn(fn -> loop(TodoList.new()) end)
    |> Process.register(:todo_server)
  end

  def add_entry(new_entry) do
    send(:todo_server, {:add_entry, new_entry})
  end

  def entries(date) do
    send(:todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 ->
        {:error, :timeout}
    end
  end

  defp loop(todo_list) do
    new_todo_list =
      receive do
        message ->
          process_message(todo_list, message)
      end

    loop(new_todo_list)
  end

  defp process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end
end

defmodule TodoList do
  defstruct auto_id: 1, entries: Map.new()

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(%TodoList{entries: entries, auto_id: auto_id} = todo_list, entry) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)
    %TodoList{todo_list | entries: new_entries, auto_id: auto_id + 1}
  end

  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn {_, entry} ->
      entry.date == date
    end)
    |> Enum.map(fn {_, entry} ->
      entry
    end)
  end

  def delete_entry(%TodoList{entries: entries} = todo_list, target_id) do
    case entries[target_id] do
      nil ->
        todo_list

      _ ->
        new_entries =
          entries
          |> Stream.filter(fn {_, entry} ->
            entry.id == target_id
          end)

        %TodoList{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(%TodoList{entries: entries} = todo_list, target_id, updater) do
    new_entries =
      entries
      |> Enum.map(fn {id, entry} ->
        case id do
          ^target_id -> safeUpdater(entry, updater)
          _ -> entry
        end
      end)

    %TodoList{todo_list | entries: new_entries}
  end

  defp safeUpdater(entry, updater) do
    old_entry_id = entry.id
    new_entry = %{id: ^old_entry_id} = updater.(entry)
    new_entry
  end
end

defmodule TodoList.CsvImporter do
  def import(filePath) do
    File.stream!(filePath)
    |> Stream.map(&(String.replace(&1, "\n", "") |> String.split(",")))
    |> Enum.map(fn [strDate, title] ->
      date =
        String.split(strDate, "/")
        |> Enum.map(&(Integer.parse(&1) |> elem(0)))
        |> listToTuple

      %{date: date, title: title}
    end)
    |> TodoList.new()
  end

  defp listToTuple(arr) do
    arr
    |> Enum.reduce({}, &Tuple.append(&2, &1))
  end
end

defimpl String.Chars, for: TodoList do
  def to_string(_) do
    "#TodoList"
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_, :halt), do: :ok
end
