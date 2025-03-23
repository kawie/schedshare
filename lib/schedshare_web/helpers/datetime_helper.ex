defmodule SchedshareWeb.DatetimeHelper do
  @timezone "Europe/Berlin"

  def to_berlin(%DateTime{} = datetime) do
    DateTime.shift_zone!(datetime, @timezone)
  end

  def format_date(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%B %d, %Y")
  end

  def format_time(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%H:%M")
  end

  def format_datetime(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_datetime_pretty(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%B %d, %Y at %H:%M")
  end

  def format_weekday_date(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%A, %B %d, %Y")
  end
end
