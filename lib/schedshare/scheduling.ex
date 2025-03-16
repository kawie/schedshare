defmodule Schedshare.Scheduling do
  @moduledoc """
  The Scheduling context.
  """

  import Ecto.Query, warn: false
  alias Schedshare.Repo

  alias Schedshare.Scheduling.Schedule
  alias Schedshare.Scheduling.Booking

  @doc """
  Returns the list of schedules for a user.
  """
  def list_user_schedules(user_id) do
    Schedule
    |> where([s], s.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload(:bookings)
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
end
