defmodule Tempo.Algebra do
  alias Tempo.Validation

  @doc """
  Expand a Tempo expression that might have
  ranges in it (one or more than one)

  """
  def expand([]) do
    []
  end

  def expand([%Range{} = range | t]) do
    accum(range, expand(t))
  end

  def expand([h | t]) do
    accum(h, expand(t))
  end

  def accum({type, %Range{} = range}, [h | _t] = list) when is_list(h) do
    Enum.flat_map(range, fn i ->
      Enum.map(list, fn elem ->
        accum({type, i}, elem)
      end)
    end)
  end

  def accum({type, %Range{} = range}, list) do
    Enum.map(range, fn i -> accum({type, i}, list) end)
  end

  def accum(elem, [h | _t] = list) when is_list(h) do
    Enum.map(list, fn e -> accum(elem, e) end)
  end

  def accum(elem, list) do
    [elem | list]
  end

  @doc """
  Get the next "odomoter reading" list of integers and ranges
  or a list of time units

  """
  def next(%Tempo{time: units, calendar: calendar} = tempo) do
    case next(units, calendar) do
      nil -> nil
      other -> %{tempo | time: other}
    end
  end

  def next(list, calendar) when is_list(list) do
    case do_next(list, calendar, []) do
      {:rollover, _list} -> nil
      {:no_cycles, _list} -> nil
      list -> list
    end
  end

  def do_next([], _calendar, _previous) do
    []
  end

  def do_next([{unit, h} | t], calendar, previous) when is_atom(unit) and is_list(h) do
    [{unit, cycle(h, unit, calendar, previous)} | List.wrap(do_next(t, [{unit, h} | previous], calendar))]
  end

  # def do_next([h | t]) when is_list(h) do
  #   [cycle(h) | List.wrap(do_next(t))]
  # end

  def do_next([{unit, {_acc, fun}}], calendar, previous) when is_atom(unit) and is_function(fun) do
    case fun.(calendar, previous) do
      {{:rollover, acc}, fun} ->
        {:rollover, [{unit, {acc, fun}}]}
      {acc, fun} ->
        [{unit, {acc, fun}}]
    end
  end

  def do_next([{unit, {acc, fun}} | t], calendar, previous) when is_atom(unit) and is_function(fun) do
    case do_next(t, calendar, previous) do
      {state, list} when state in [:rollover, :no_cycles] ->
        case fun.(calendar, previous) do
          {{:rollover, acc}, fun} ->
            {:rollover, [{unit, {acc, fun}} | list]}
          {acc, fun} ->
            [{unit, {acc, fun}} | list]
        end

      list ->
        [{unit, {acc, fun}} | list]
    end
  end

  def do_next({:no_cycles, h}, _calendar, _previous) do
    {:no_cycles, h}
  end

  def do_next([h], _calendar, _previous) do
    {:no_cycles, [h]}
  end

  def do_next([h | t], calendar, previous) do
    case do_next(t, calendar, previous) do
      {:no_cycles, list} ->
        {:no_cycles, [h | list]}

      {:rollover, list} ->
        {:rollover, [h | list]}

      list ->
        [h | list]
    end
  end

  @doc """
  Returns a function that when called will return
  the next cycle value in a sequence.

  When the sequence cycles back to the start
  it returns `{:rollover, value}` to signal
  the rollover.

  """
  def cycle(source, unit, calendar, previous) when is_list(source) do
    cycle(source, source, unit, calendar, previous)
  end

  # def cycle(%Range{} = range, unit, previous) do
  #   cycle(range, range, unit, previous)
  # end

  defp cycle(source, list, unit, calendar, previous) when is_list(list)do
    case list do
      [] ->
        rollover(source, unit, calendar, previous)

      [%Range{step: step} = range | tail] when step < 1 ->
        %Range{first: first, last: last, step: step} = adjusted_range(range, unit, calendar, previous)
        {first, fn previous -> cycle(source, [(first + step)..last//step | tail], unit, calendar, previous) end}

      [%Range{first: first, last: last, step: step} | tail] when first <= last ->
        {first, fn previous -> cycle(source, [(first + step)..last//step | tail], unit, calendar, previous) end}

      [%Range{}] ->
        rollover(source, unit, calendar, previous)

      [%Range{}, next | tail] ->
        {next, fn previous -> cycle(source, tail, unit, calendar, previous) end}

      [head | tail] ->
        {head, fn previous -> cycle(source, tail, unit, calendar, previous) end}
    end
  end

  defp rollover([h | t] = source, unit, calendar, previous) do
    case h do
      %Range{step: step} = range when step < 1 ->
        %Range{first: first, last: last, step: step} = adjusted_range(range, unit, calendar, previous)
        {{:rollover, first}, fn -> cycle(source, [(first + step)..last//step | t], unit, calendar, previous) end}
      %Range{first: first, last: last, step: step} ->
        {{:rollover, first}, fn -> cycle(source, [(first + step)..last//step | t], unit, calendar, previous) end}
      first ->
        {{:rollover, first}, fn -> cycle(source, t, unit, calendar, previous) end}
    end
  end

  defp adjusted_range(range, unit, calendar, previous) do
    units = [{unit, range} | current_units(previous)] |> Enum.reverse()

    {_unit, range} =
      units
      |> Validation.validate(calendar)
      |> Enum.reverse()
      |> hd

    range
  end

  def current_units(units) do
    Enum.map units, fn
      {unit, list} when is_list(list) -> {unit, extract_first(list)}
      {unit, {current, _fun}} -> {unit, current}
      {:no_cycles, list} -> list
      {unit, value} -> {unit, value}
    end
  end

  def extract_first([%Range{first: first} | _rest]), do: first
  def extract_first([first | _rest]), do: first

  @doc """
  Strips the functions from return tuples to produce
  a clean structure to pass to functions

  """
  def collect(%Tempo{time: units} = tempo) do
    case collect(units) do
      nil -> nil
      other -> %{tempo | time: other}
    end
  end

  def collect([]) do
    []
  end

  def collect([{:no_cycles, list}]) do
    list
  end

  def collect([{value, fun} | t]) when is_function(fun) do
    [value | collect(t)]
  end

  def collect([{unit, {acc, fun}} | t]) when is_function(fun) do
    [{unit, acc} | collect(t)]
  end

  def collect([h | t]) do
    [h | collect(t)]
  end
end