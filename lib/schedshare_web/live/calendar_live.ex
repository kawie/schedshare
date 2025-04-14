defmodule SchedshareWeb.CalendarLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Scheduling
  alias SchedshareWeb.DatetimeHelper
  require Logger

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      # Get the next 14 days in Berlin time
      today = DateTime.utc_now() |> DatetimeHelper.to_berlin()
      end_date = DateTime.add(today, 13 * 24 * 60 * 60, :second)

      Logger.debug("Calendar: Fetching bookings from #{inspect(today)} to #{inspect(end_date)}")

      # Get all bookings for the date range
      bookings = get_bookings_for_date_range(socket.assigns.current_user.id, today, end_date)
      Logger.debug("Calendar: Found #{length(bookings)} bookings")

      # Group bookings by date
      grouped_bookings = group_bookings_by_date(bookings)
      Logger.debug("Calendar: Grouped into #{map_size(grouped_bookings)} days")

      {:ok,
       assign(socket,
         page_title: "Calendar",
         bookings: bookings,
         grouped_bookings: grouped_bookings,
         today: today,
         end_date: end_date
       )}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  defp get_bookings_for_date_range(user_id, start_date, end_date) do
    # Get current user's bookings
    user_bookings =
      case Scheduling.list_user_schedules(user_id) do
        [schedule] ->
          Logger.debug("Calendar: Found #{length(schedule.bookings)} bookings for user #{user_id}")
          # Preload the schedule and user associations
          schedule.bookings
          |> Enum.map(fn booking ->
            booking
            |> Schedshare.Repo.preload([:schedule])
            |> Schedshare.Repo.preload(schedule: [:user])
          end)
        _ ->
          Logger.debug("Calendar: No schedule found for user #{user_id}")
          []
      end

    # Get friends' bookings
    friend_bookings = Scheduling.list_recent_friend_bookings(user_id)
    Logger.debug("Calendar: Found #{length(friend_bookings)} bookings from friends")

    # Combine and filter bookings
    all_bookings = user_bookings ++ friend_bookings
    Logger.debug("Calendar: Total bookings before filtering: #{length(all_bookings)}")

    filtered_bookings = all_bookings
    |> Enum.reject(&(&1.status in ["DELETED", "CANCELLED"]))
    |> Enum.filter(fn booking ->
      # Convert booking dates to Berlin time for comparison
      booking_start = booking.start_datetime_utc |> DatetimeHelper.to_berlin()
      booking_start >= start_date and booking_start <= end_date
    end)

    Logger.debug("Calendar: Total bookings after filtering: #{length(filtered_bookings)}")
    filtered_bookings
  end

  defp group_bookings_by_date(bookings) do
    bookings
    |> Enum.group_by(fn booking ->
      # Convert to Berlin time for grouping
      booking.start_datetime_utc
      |> DatetimeHelper.to_berlin()
      |> DateTime.to_date()
    end)
    |> Enum.map(fn {date, day_bookings} ->
      # Group bookings that are the same course
      grouped_day_bookings =
        day_bookings
        |> Enum.group_by(fn booking ->
          {booking.course_external_id, booking.start_datetime_utc}
        end)
        |> Enum.map(fn {_, same_bookings} ->
          # Sort by user ID to ensure consistent order
          same_bookings = Enum.sort_by(same_bookings, & &1.schedule.user_id)
          # Use the first booking as the base
          base_booking = hd(same_bookings)
          # Add all users to the base booking
          %{base_booking | schedule: %{base_booking.schedule |
            user: same_bookings |> Enum.map(& &1.schedule.user)
          }}
        end)

      {date, grouped_day_bookings}
    end)
    |> Map.new()
  end

  defp dates_in_range(start_date, end_date) do
    start_date = DateTime.to_date(start_date)
    end_date = DateTime.to_date(end_date)
    Enum.map(0..Date.diff(end_date, start_date), &Date.add(start_date, &1))
  end
end
