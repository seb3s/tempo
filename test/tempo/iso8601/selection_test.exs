defmodule Tempo.Parser.Selection.Test do
  use ExUnit.Case, async: true

  test "selections" do
    # First Monday in March, 2018
    assert Tempo.from_iso8601("2018Y3ML1K1IN") ==
      {:ok, [year: 2018, month: 3, selection: [day_of_week: 1, instance: 1]]}

    # September 2018, 3rd instance of 08:20
    assert Tempo.from_iso8601("2018Y9MTLT8H20M3IN") ==
      {:ok, [year: 2018, month: 9, selection: [hour: 8, minute: 20, instance: 3]]}

    # First instance of February 29th in the years 2018..2022
    assert Tempo.from_iso8601("{2018,2019,2020,2021,2022}YL2M29D1IN") ==
      {:ok,
        [year: [2018..2022], selection: [month: 2, day_of_month: 29, instance: 1]]}

    # Second Sunday in May
    assert Tempo.from_iso8601("L5M7K2IN") ==
      {:ok, [selection: [month: 5, day_of_week: 7, instance: 2]]}

    # 5:00:00 p.m. of the fourth Thursday in November, in UTC-05:00
    assert Tempo.from_iso8601("X*YL11M4K4INT17HZ-5H") ==
      {:ok,
       [
         year: ["X*"],
         selection: [month: 11, day_of_week: 4, instance: 4],
         hour: 17,
         time_shift: [hour: -5]
       ]}

    # first Thursday after April 18th
    assert Tempo.from_iso8601("L4M{19..26}D4K1IN") ==
      {:ok,
       [
         selection: [
           month: 4,
           day_of_month: [19..26],
           day_of_week: 4,
           instance: 1
         ]
       ]}

    # Tuesday following the first Monday of November of any four-digit even numbered year
    assert Tempo.from_iso8601("XXX{0,2,4,6,8}Y11MLLL1K1IN/P9DN2K1IN") ==
      {
        :ok,
        [
          year: {:mask, [:X, :X, :X, [0, 2, 4, 6, 8]]},
          month: 11,
          selection: [
            interval: [date: [selection: [day_of_week: 1, instance: 1]], duration: [day: 9]],
            day_of_week: 2,
            instance: 1
          ]
        ]
      }

    # First Monday in 2018
    assert Tempo.from_iso8601("2018YL1K1IN") ==
      {:ok, [year: 2018, selection: [day_of_week: 1, instance: 1]]}

    # First Monday in 2018 at 10am
    assert Tempo.from_iso8601("2018YL1K1INT10H0M0S") ==
      {:ok,
       [
         year: 2018,
         selection: [day_of_week: 1, instance: 1],
         hour: 10,
         minute: 0,
         second: 0
       ]}

    # Every Monday, Tuesday and Friday in 2018
    assert Tempo.from_iso8601("2018YL{1,2,5}KN") ==
      {:ok, [year: 2018, selection: [day_of_week: [1..2, 5]]]}

    # First Monday in September for 5 days
    assert Tempo.from_iso8601("2018Y9ML1K1IN/P5D") ==
      {:ok,
       [
         date: [year: 2018, month: 9, selection: [day_of_week: 1, instance: 1]],
         duration: [day: 5]
       ]}

    # First and third Monday in September for 5 days
    assert Tempo.from_iso8601("2018Y9ML{1,3}K1IN/P5D") ==
        {:ok,
         [
           date: [year: 2018, month: 9, selection: [day_of_week: [1, 3], instance: 1]],
           duration: [day: 5]
         ]}
  end

  test "fix me" do
    assert Tempo.from_iso8601("LL4M4D/-P20DN7K-2IN") ==
      {:ok,
        [
          selection: [
            interval: [date: [month: 4, day_of_month: 4],
            duration: [direction: :negative, day: 20]],
            day_of_week: 7, instance: -2]]}
  end
end