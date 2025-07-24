defmodule SchedshareWeb.CalendarController do
  use SchedshareWeb, :controller
  alias Schedshare.Accounts
  alias Schedshare.Scheduling
  import DateTime

  def calendar_ics(conn, %{"user_id" => user_id, "token" => token}) do
    with {:ok, user} <- Accounts.get_user_by_id_and_token(user_id, token),
         bookings <- Scheduling.get_upcoming_bookings_for_user(user_id) do

      now = DateTime.now_utc()
      ics_content = generate_ics_content(bookings, user, now)
      
      conn
      |> put_resp_content_type("text/calendar")
      |> put_resp_header("content-disposition", "attachment; filename=calendar.ics")
      |> send_resp(200, ics_content)
    else
      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> text("Not Found")
      {:error, :invalid_token} ->
        conn
        |> put_status(403)
        |> text("Invalid Token")
    end
  end

  defp generate_ics_content(bookings, user, now) do
    "BEGIN:VCALENDAR\n" 
    <> "VERSION:2.0\n" 
    <> "PRODID:-//Schedshare//Calendar//EN\n"
    <> "CALSCALE:GREGORIAN\n"
    <> "METHOD:PUBLISH\n"
    <> Enum.map_join(bookings, "\n", fn booking ->
      generate_event(booking, user, now)
    end)
    <> "\nEND:VCALENDAR"
  end

  defp generate_event(booking, user, now) do
    start_time = booking.start_datetime_utc
    end_time = booking.end_datetime_utc
    
    "BEGIN:VEVENT\n" 
    <> "UID:#{booking.id}@schedshare.com\n"
    <> "DTSTAMP:#{format_datetime(now)}\n"
    <> "DTSTART:#{format_datetime(start_time)}\n"
    <> "DTEND:#{format_datetime(end_time)}\n"
    <> "SUMMARY:#{escape(booking.course_title)}\n"
    <> "LOCATION:#{escape(booking.venue_full_address)}\n"
    <> "DESCRIPTION:#{generate_description(booking, user)}\n"
    <> "URL:#{escape(generate_booking_url(booking))}\n"
    <> "END:VEVENT"
  end

  defp generate_description(booking, user) do
    description = 
      "Trainer: #{booking.teacher_name}\n" 
      <> "Booking Type: #{booking.booking_type}\n"
      <> "Service Type: #{booking.service_type}\n"
      <> "\nExternal Booking Link: #{generate_external_booking_url(booking)}"
    
    # Add friends if they're going together
    friends = Scheduling.get_friends_going_together(booking.id, user.id)
    if friends != [] do
      description <> "\n\nGoing Together With: " <> Enum.map_join(friends, ", ", &(&1.name || &1.email))
    else
      description
    end
  end

  defp format_datetime(datetime) do
    DateTime.to_iso8601(datetime, :basic)
    |> String.replace("T", "")
    |> String.replace(":", "")
    |> String.replace(".", "")
  end

  defp escape(text) do
    text
    |> String.replace("\n", "\\n")
    |> String.replace(":", "\\:")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
  end

  defp generate_booking_url(booking) do
    "/bookings/#{booking.id}"
  end

  defp generate_external_booking_url(booking) do
    "https://bookingplatform.com/course/#{booking.course_external_id}"
  end
end
