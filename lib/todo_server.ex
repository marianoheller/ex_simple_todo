defmodule TodoServer2 do
  use GenServer

  def start do
    GenServer.start(TodoServer2, nil)
  end

  def put(pid, new_entry) do
    GenServer.cast(pid, {:put, new_entry})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def init(_) do
    {:ok, TodoList2.new()}
  end

  def handle_cast({:put, new_entry}, state) do
    {:noreply, TodoList2.add_entry(state, new_entry)}
  end

  def handle_call({:get, key}, _, state) do
    {:reply, TodoList2.entries(state, key), state}
  end
end

defmodule TodoList2 do
  defstruct auto_id: 1, entries: Map.new()

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList2{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(%TodoList2{entries: entries, auto_id: auto_id} = todo_list, entry) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = Map.put(entries, auto_id, entry)
    %TodoList2{todo_list | entries: new_entries, auto_id: auto_id + 1}
  end

  def entries(%TodoList2{entries: entries}, date) do
    entries
    |> Stream.filter(fn {_, entry} ->
      entry.date == date
    end)
    |> Enum.map(fn {_, entry} ->
      entry
    end)
  end

  def delete_entry(%TodoList2{entries: entries} = todo_list, target_id) do
    case entries[target_id] do
      nil ->
        todo_list

      _ ->
        new_entries =
          entries
          |> Stream.filter(fn {_, entry} ->
            entry.id == target_id
          end)

        %TodoList2{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(%TodoList2{entries: entries} = todo_list, target_id, updater) do
    new_entries =
      entries
      |> Enum.map(fn {id, entry} ->
        case id do
          ^target_id -> safeUpdater(entry, updater)
          _ -> entry
        end
      end)

    %TodoList2{todo_list | entries: new_entries}
  end

  defp safeUpdater(entry, updater) do
    old_entry_id = entry.id
    new_entry = %{id: ^old_entry_id} = updater.(entry)
    new_entry
  end
end
