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

  def format_datetime(datetime) when is_nil(datetime), do: "Never"
  def format_datetime(datetime) do
    # Convert to Berlin time for display
    berlin_time = DateTime.shift_zone!(datetime, "Europe/Berlin")
    Calendar.strftime(berlin_time, "%Y-%m-%d %H:%M")
  end

  def format_datetime_pretty(datetime) when not is_nil(datetime) do
    datetime
    |> to_berlin()
    |> Calendar.strftime("%B %d, %Y at %H:%M")
  end

  def format_weekday_date(datetime) do
    # Convert to Berlin time for display
    berlin_time = DateTime.shift_zone!(datetime, "Europe/Berlin")
    Calendar.strftime(berlin_time, "%A, %B %d")
  end

  def format_relative_time(datetime) when is_nil(datetime), do: "Never"
  def format_relative_time(datetime) do
    # Convert to UTC for comparison
    utc_time = case datetime do
      %DateTime{} -> datetime
      %NaiveDateTime{} ->
        {:ok, dt} = DateTime.from_naive(datetime, "Etc/UTC")
        dt
    end

    now = DateTime.utc_now()
    diff = DateTime.diff(now, utc_time, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 7200 -> "1 hour ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 172800 -> "1 day ago"
      diff < 2592000 -> "#{div(diff, 86400)} days ago"
      diff < 5184000 -> "1 month ago"
      true -> "#{div(diff, 2592000)} months ago"
    end
  end
end
