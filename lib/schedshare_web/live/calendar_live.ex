defmodule SchedshareWeb.CalendarLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Scheduling
  alias SchedshareWeb.DatetimeHelper
  require Logger

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      # Get the next 14 days in Berlin time
      today = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00], "Europe/Berlin")
      end_date = DateTime.add(today, 13 * 24 * 60 * 60, :second)

      # Get all bookings for the date range
      bookings = get_bookings_for_date_range(socket.assigns.current_user.id, today, end_date)

      # Group bookings by date
      grouped_bookings = group_bookings_by_date(bookings)

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
          schedule.bookings
          |> Enum.map(fn booking ->
            booking
            |> Schedshare.Repo.preload([:schedule])
            |> Schedshare.Repo.preload(schedule: [:user])
          end)
        _ -> []
      end

    # Get friends' bookings
    friend_bookings = Scheduling.list_recent_friend_bookings(user_id)

    # Combine and filter bookings
    (user_bookings ++ friend_bookings)
    |> Enum.reject(&(&1.status in ["DELETED", "CANCELLED"]))
    |> Enum.filter(fn booking ->
      booking_date = booking.start_datetime_utc
        |> DatetimeHelper.to_berlin()
        |> DateTime.to_date()

      range_start_date = DateTime.to_date(start_date)
      range_end_date = DateTime.to_date(end_date)

      start_comparison = Date.compare(booking_date, range_start_date)
      end_comparison = Date.compare(booking_date, range_end_date)

      start_comparison != :lt and end_comparison != :gt
    end)
  end

  defp group_bookings_by_date(bookings) do
    bookings
    |> Enum.group_by(fn booking ->
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
