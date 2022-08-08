defmodule Tempo.Iso8601.Tokenizer do
  import NimbleParsec
  import Tempo.Iso8601.Tokenizer.Numbers
  import Tempo.Iso8601.Tokenizer.Grammar
  import Tempo.Iso8601.Tokenizer.Helpers

  # def date(string) do
  #   string
  #   |> date_parser()
  #   |> return(string)
  # end
  #
  # def time(string) do
  #   string
  #   |> time_parser()
  #   |> return(string)
  # end
  #
  # def date_time(string) do
  #   string
  #   |> datetime_parser()
  #   |> return(string)
  # end
  #
  # def interval(string) do
  #   string
  #   |> interval_parser()
  #   |> return(string)
  # end
  #
  # def duration(string) do
  #   string
  #   |> duration_parser()
  #   |> return(string)
  # end

  def tokenize(string) do
    string
    |> iso8601()
    |> return(string)
  end

  defp return(result, string) do
    case result do
      {:ok, tokens, "", %{}, {_, _}, _} ->
        {:ok, tokens}

      {:ok, _tokens, remaining, _, {_line, _}, _char} ->
        {:error, "Could not parse #{inspect(string)}. Error detected at #{inspect(remaining)}"}

      {:error, message, detected_at, _, _, _} ->
        {:error, String.capitalize(message) <> ". Error detected at #{inspect(detected_at)}"}
    end
  end

  defparsec :iso8601, iso8601_tokenizer()

  defcombinator :set,
                choice([
                  parsec(:set_all),
                  parsec(:set_one),
                  parsec(:interval_parser),
                  parsec(:datetime_or_date_or_time)
                ])

  defparsec :integer_or_integer_set,
    choice([
      integer(min: 1) |> unwrap_and_tag(:nth),
      parsec(:integer_set_all),
      parsec(:integer_set_one)
    ])
    |> label("integer or integer set")

  defparsec :set_all,
    ignore(string("{"))
    |> list_of_time_or_range()
    |> ignore(string("}"))
    |> tag(:all_of)

  defparsec :set_one,
    ignore(string("["))
    |> list_of_time_or_range()
    |> ignore(string("]"))
    |> tag(:one_of)

  defparsec :integer_set_all,
    ignore(string("{"))
    |> list_of_integer_or_range()
    |> ignore(string("}"))
    |> tag(:all_of)

  defparsec :integer_set_one,
    ignore(string("["))
    |> list_of_integer_or_range()
    |> ignore(string("]"))
    |> tag(:one_of)

  defparsec :interval_parser,
            optional(recurrence())
            |> choice([
              parsec(:datetime_or_date_or_time)
              |> ignore(string("/"))
              |> parsec(:datetime_or_date_or_time),
              parsec(:datetime_or_date_or_time)
              |> ignore(string("/"))
              |> parsec(:duration_parser),
              parsec(:duration_parser) |> ignore(string("/")) |> parsec(:datetime_or_date_or_time)
            ])
            |> tag(:interval)
            |> label("interval")

  defparsec :datetime_or_date_or_time,
                choice([
                  parsec(:datetime_parser),
                  parsec(:date_parser),
                  parsec(:time_parser)
                ])

  defparsec :datetime_parser,
            choice([
              explicit_date_time(),
              implicit_date_time_x(),
              implicit_date_time()
            ])
            |> tag(:datetime)

  defparsec :date_parser,
            choice([
              explicit_date(),
              implicit_date_x() |> optional(time_shift_x()),
              implicit_date() |> optional(time_shift())
            ])
            |> tag(:date)
            |> label("date")

  defparsec :time_parser,
            choice([
              explicit_time_of_day(),
              implicit_time_of_day_x(),
              implicit_time_of_day()
            ])
            |> tag(:time_of_day)
            |> label("time of day")

  defcombinator :group,
                parsec(:integer_or_integer_set)
                |> ignore(string("G"))
                |> duration_elements()
                |> ignore(string("U"))
                |> tag(:group)
                |> label("group")

  defparsec :duration_parser,
            optional(negative() |> replace({:direction, :negative}))
            |> ignore(string("P"))
            |> concat(duration_elements())
            |> tag(:duration)
            |> label("duration")
end
