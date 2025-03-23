defmodule Schedshare.Scheduling do
  @moduledoc """
  The Scheduling context.
  """

  import Ecto.Query, warn: false
  alias Schedshare.Repo

  alias Schedshare.Scheduling.Schedule
  alias Schedshare.Scheduling.Booking
  alias Schedshare.Scheduling.ApiCredential

  @doc """
  Returns a list of active API credentials.
  A credential is considered active if:
  1. It has a valid access token
  2. Its connection_status is "connected"
  3. Its last sync was successful (no connection_error)
  """
  def list_active_api_credentials do
    ApiCredential
    |> where([c], c.connection_status == "connected")
    |> where([c], is_nil(c.connection_error))
    |> where([c], not is_nil(c.access_token))
    |> Repo.all()
  end

  @doc """
  Returns the list of schedules for a user.
  """
  def list_user_schedules(user_id) do
    Schedule
    |> where([s], s.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload([bookings: from(b in Booking, order_by: [asc: b.start_datetime_utc])])
  end

  @doc """
  Gets a single schedule.
  """
  def get_schedule!(id), do: Repo.get!(Schedule, id)

  @doc """
  Creates a schedule.
  """
  def create_schedule(attrs \\ %{}) do
    %Schedule{}
    |> Schedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a schedule.
  """
  def update_schedule(%Schedule{} = schedule, attrs) do
    schedule
    |> Schedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a schedule.
  """
  def delete_schedule(%Schedule{} = schedule) do
    Repo.delete(schedule)
  end

  @doc """
  Returns the list of bookings for a schedule.
  """
  def list_schedule_bookings(schedule_id) do
    Booking
    |> where([b], b.schedule_id == ^schedule_id)
    |> order_by([b], asc: b.start_datetime_utc)
    |> Repo.all()
  end

  @doc """
  Gets a single booking.
  """
  def get_booking!(id), do: Repo.get!(Booking, id)

  @doc """
  Creates a booking.
  """
  def create_booking(attrs \\ %{}) do
    %Booking{}
    |> Booking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a booking.
  """
  def update_booking(%Booking{} = booking, attrs) do
    booking
    |> Booking.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a booking.
  """
  def delete_booking(%Booking{} = booking) do
    Repo.delete(booking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking schedule changes.
  """
  def change_schedule(%Schedule{} = schedule, attrs \\ %{}) do
    Schedule.changeset(schedule, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking booking changes.
  """
  def change_booking(%Booking{} = booking, attrs \\ %{}) do
    Booking.changeset(booking, attrs)
  end

  @doc """
  Returns a list of bookings from other users' schedules that match the given booking's course_external_id.
  Only returns bookings from users that the current user follows.
  """
  def get_matching_bookings(booking, current_user_id) do
    followed_users_query =
      from f in Schedshare.Accounts.Follow,
        where: f.follower_id == ^current_user_id and f.status == :approved,
        select: f.followed_id

    base_query = Booking
    |> join(:inner, [b], s in Schedule, on: b.schedule_id == s.id)
    |> where([b, s], s.user_id != ^current_user_id)
    |> where([b, s], s.user_id in subquery(followed_users_query))
    |> where([b], b.status not in ["DELETED", "CANCELLED"])  # Filter out cancelled/deleted bookings

    query = if is_nil(booking.course_external_id) do
      # If course_external_id is nil, match on title and start_datetime_utc
      base_query
      |> where([b], is_nil(b.course_external_id))
      |> where([b], b.course_title == ^booking.course_title)
      |> where([b], b.start_datetime_utc == ^booking.start_datetime_utc)
    else
      # Otherwise match on course_external_id
      base_query
      |> where([b], b.course_external_id == ^booking.course_external_id)
    end

    query
    |> preload([b, s], schedule: {s, :user})
    |> Repo.all()
  end

  @doc """
  Returns a list of users who are also booked into the same course.
  Only includes users that the current user follows.
  """
  def get_users_in_same_course(booking, current_user_id) do
    booking
    |> get_matching_bookings(current_user_id)
    |> Enum.map(& &1.schedule.user)
  end

  @doc """
  Gets the API credential for a user.
  """
  def get_user_api_credential(user_id) do
    ApiCredential
    |> where([c], c.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Creates or updates an API credential for a user.
  """
  def create_or_update_api_credential(user_id, attrs) do
    case get_user_api_credential(user_id) do
      nil ->
        %ApiCredential{user_id: user_id}
        |> ApiCredential.changeset(attrs)
        |> Repo.insert()

      credential ->
        credential
        |> ApiCredential.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates an API credential.
  """
  def update_api_credential(%ApiCredential{} = credential, attrs) do
    credential
    |> ApiCredential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking API credential changes.
  """
  def change_api_credential(%ApiCredential{} = credential, attrs \\ %{}) do
    ApiCredential.changeset(credential, attrs)
  end

  @doc """
  Syncs bookings from the API response.
  Updates existing bookings if they have the same external_id, creates new ones if they don't exist.
  Marks bookings as DELETED if they're no longer returned by the API.
  """
  def sync_bookings(user_id, bookings) do
    # Get or create schedule for user
    schedule =
      case list_user_schedules(user_id) do
        [schedule] -> schedule
        _ -> {:ok, schedule} = create_schedule(%{user_id: user_id})
             schedule
      end

    # Get existing bookings by external_id for this schedule
    existing_bookings =
      Booking
      |> where([b], b.schedule_id == ^schedule.id)
      |> Repo.all()
      |> Map.new(&{&1.external_id, &1})

    # Get list of external_ids from API response
    api_external_ids = Enum.map(bookings, & &1["id"]) |> MapSet.new()

    # Mark bookings as DELETED if they're not in the API response
    existing_bookings
    |> Enum.filter(fn {external_id, _} -> not MapSet.member?(api_external_ids, external_id) end)
    |> Enum.each(fn {_, booking} ->
      update_booking(booking, %{status: "DELETED"})
    end)

    # Convert API bookings to our format and sync them
    bookings
    |> Enum.map(fn booking ->
      # Parse the datetime with timezone info and convert to Berlin time for display
      {:ok, start_datetime, _} = DateTime.from_iso8601(booking["start_time"])
      {:ok, end_datetime, _} = DateTime.from_iso8601(booking["end_time"])

      %{
        schedule_id: schedule.id,
        external_id: booking["id"],
        course_external_id: booking["course_external_id"],
        status: booking["status"],
        course_title: booking["title"],
        start_datetime_utc: start_datetime,  # Keep UTC for storage
        end_datetime_utc: end_datetime,      # Keep UTC for storage
        venue_name: booking["location"],
        teacher_name: booking["teacher_name"],
        course_types: booking["course_types"] || [],
        is_online: booking["is_online"] || false
      }
    end)
    |> Enum.reduce_while({:ok, []}, fn booking_attrs, {:ok, acc} ->
      case Map.get(existing_bookings, booking_attrs.external_id) do
        nil ->
          # Create new booking if it doesn't exist
          case create_booking(booking_attrs) do
            {:ok, booking} -> {:cont, {:ok, [booking | acc]}}
            {:error, _} -> {:halt, {:error, "Failed to create booking"}}
          end

        existing_booking ->
          # Update existing booking
          case update_booking(existing_booking, booking_attrs) do
            {:ok, booking} -> {:cont, {:ok, [booking | acc]}}
            {:error, _} -> {:halt, {:error, "Failed to update booking"}}
          end
      end
    end)
  end

  @doc """
  Returns a list of API credentials that need syncing for a user and their followed users.
  A credential needs syncing if:
  1. It has a valid access token
  2. Its connection_status is "connected"
  3. Its last sync was successful (no connection_error)
  4. It hasn't been synced in the last hour
  5. It belongs to either:
     - The current user
     - A user that the current user follows
  """
  def list_credentials_needing_sync(current_user_id) do
    require Logger
    one_hour_ago = DateTime.add(DateTime.utc_now(), -3600, :second)

    # Get IDs of users that the current user follows
    followed_users_query =
      from f in Schedshare.Accounts.Follow,
        where: f.follower_id == ^current_user_id and f.status == :approved,
        select: f.followed_id

    followed_users = Repo.all(followed_users_query)
    Logger.debug("User #{current_user_id} follows users: #{inspect(followed_users)}")

    # Get credentials that need syncing
    query = ApiCredential
    |> where([c], c.connection_status == "connected")
    |> where([c], is_nil(c.connection_error))
    |> where([c], not is_nil(c.access_token))
    |> where([c],
      # Either no last sync, or last sync was more than an hour ago
      is_nil(c.last_sync_at) or c.last_sync_at < ^one_hour_ago
    )
    |> where([c],
      # Belongs to current user or a followed user
      c.user_id == ^current_user_id or c.user_id in subquery(followed_users_query)
    )

    credentials = Repo.all(query)
    Logger.debug("Found credentials needing sync: #{inspect(Enum.map(credentials, & &1.user_id))}")
    Logger.debug("Query conditions: connection_status=connected, no error, has token, last_sync < #{DateTime.to_string(one_hour_ago)}")

    credentials
  end
end
