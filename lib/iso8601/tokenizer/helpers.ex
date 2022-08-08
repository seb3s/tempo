defmodule Tempo.Iso8601.Tokenizer.Helpers do
  import NimbleParsec

  def recur([]), do: :infinity
  def recur([other]), do: other

  def sign do
    ascii_char([?+, ?-])
    |> unwrap_and_tag(:sign)
  end

  def zulu do
    ascii_char([?Z])
  end

  def colon do
    ascii_char([?:])
  end

  def dash do
    ascii_char([?-])
  end

  def decimal_separator do
    ascii_char([?,, ?.])
  end

  def negative do
    ascii_char([?-])
  end

  def digit do
    ascii_char([?0..?9])
  end

  def unknown do
    ascii_char([?X])
  end

  def all_unknown do
    string("X*")
  end

  def day_of_week do
    ascii_char([?1..?7])
    |> reduce({List, :to_integer, []})
  end

  def convert_bc([int, "B"]) do
    -(int - 1)
  end

  def convert_bc([other]) do
    other
  end
end
