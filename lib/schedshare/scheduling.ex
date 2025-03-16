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
end
