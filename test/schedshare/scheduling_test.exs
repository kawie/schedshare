defmodule Schedshare.SchedulingTest do
  use Schedshare.DataCase

  alias Schedshare.Scheduling
  alias Schedshare.Accounts
  alias Schedshare.Accounts.User
  alias Schedshare.Scheduling.{Schedule, Booking}

  @valid_user_attrs %{
    email: "test@example.com",
    password: "hello world!"
  }

  @valid_booking_attrs %{
    external_id: 76428995,
    status: "CONFIRMED",
    course_external_id: 86888376,
    course_date: ~D[2025-03-24],
    course_title: "Vinyasa Recharge • EN",
    is_online: false,
    course_types: ["onsite"],
    start_time: ~T[16:30:00],
    end_time: ~T[17:30:00],
    start_datetime_utc: ~U[2025-03-24 15:30:00Z],
    end_datetime_utc: ~U[2025-03-24 16:30:00Z],
    venue_external_id: 3881,
    venue_name: "YOGA at Lobe Block — Lobe Block",
    venue_lat: 52.5484838,
    venue_long: 13.382659200000001,
    venue_full_address: "Böttgerstr. 16 (YOGA at Lobe Block, 1. OG), 10437 Berlin",
    city_name: "Berlin",
    district_name: "Gesundbrunnen",
    booking_type: "confirmation_required",
    external: true,
    service_type: "event",
    category_external_id: 6,
    category_name: "Yoga",
    teacher_name: "Ulrike"
  }

  @invalid_booking_attrs %{
    external_id: nil,
    status: nil,
    course_title: nil,
    start_datetime_utc: nil,
    end_datetime_utc: nil
  }

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_user_attrs)
      |> Accounts.register_user()

    user
  end

  def schedule_fixture(user) do
    {:ok, schedule} = Scheduling.create_schedule(%{user_id: user.id})
    schedule
  end

  def booking_fixture(schedule, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(@valid_booking_attrs)
      |> Map.put(:schedule_id, schedule.id)

    {:ok, booking} = Scheduling.create_booking(attrs)
    booking
  end

  describe "schedules" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "list_user_schedules/1 returns user's schedule", %{user: user} do
      schedule = schedule_fixture(user)
      assert Scheduling.list_user_schedules(user.id) == [schedule]
    end

    test "create_schedule/1 with valid data creates a schedule", %{user: user} do
      assert {:ok, %Schedule{}} = Scheduling.create_schedule(%{user_id: user.id})
    end

    test "create_schedule/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Scheduling.create_schedule(%{user_id: nil})
    end
  end

  describe "bookings" do
    setup do
      user = user_fixture()
      schedule = schedule_fixture(user)
      %{user: user, schedule: schedule}
    end

    test "list_schedule_bookings/1 returns all bookings for a schedule", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      assert Scheduling.list_schedule_bookings(schedule.id) == [booking]
    end

    test "get_booking!/1 returns the booking with given id", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      assert Scheduling.get_booking!(booking.id) == booking
    end

    test "create_booking/1 with valid data creates a booking", %{schedule: schedule} do
      valid_attrs = Map.put(@valid_booking_attrs, :schedule_id, schedule.id)
      assert {:ok, %Booking{} = booking} = Scheduling.create_booking(valid_attrs)
      assert booking.external_id == 76428995
      assert booking.status == "CONFIRMED"
      assert booking.course_title == "Vinyasa Recharge • EN"
      assert booking.start_datetime_utc == ~U[2025-03-24 15:30:00Z]
      assert booking.end_datetime_utc == ~U[2025-03-24 16:30:00Z]
    end

    test "create_booking/1 with invalid data returns error changeset", %{schedule: schedule} do
      invalid_attrs = Map.put(@invalid_booking_attrs, :schedule_id, schedule.id)
      assert {:error, %Ecto.Changeset{}} = Scheduling.create_booking(invalid_attrs)
    end

    test "update_booking/2 with valid data updates the booking", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      update_attrs = %{status: "CANCELLED"}

      assert {:ok, %Booking{} = booking} = Scheduling.update_booking(booking, update_attrs)
      assert booking.status == "CANCELLED"
    end

    test "update_booking/2 with invalid data returns error changeset", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      assert {:error, %Ecto.Changeset{}} = Scheduling.update_booking(booking, @invalid_booking_attrs)
      assert booking == Scheduling.get_booking!(booking.id)
    end

    test "delete_booking/1 deletes the booking", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      assert {:ok, %Booking{}} = Scheduling.delete_booking(booking)
      assert_raise Ecto.NoResultsError, fn -> Scheduling.get_booking!(booking.id) end
    end

    test "change_booking/1 returns a booking changeset", %{schedule: schedule} do
      booking = booking_fixture(schedule)
      assert %Ecto.Changeset{} = Scheduling.change_booking(booking)
    end

    test "bookings are ordered by start_datetime_utc", %{schedule: schedule} do
      # Create bookings with different start times
      booking1 = booking_fixture(schedule, %{
        external_id: 1,
        start_datetime_utc: ~U[2025-03-24 15:30:00Z],
        end_datetime_utc: ~U[2025-03-24 16:30:00Z]
      })
      booking2 = booking_fixture(schedule, %{
        external_id: 2,
        start_datetime_utc: ~U[2025-03-23 15:30:00Z],
        end_datetime_utc: ~U[2025-03-23 16:30:00Z]
      })
      booking3 = booking_fixture(schedule, %{
        external_id: 3,
        start_datetime_utc: ~U[2025-03-25 15:30:00Z],
        end_datetime_utc: ~U[2025-03-25 16:30:00Z]
      })

      bookings = Scheduling.list_schedule_bookings(schedule.id)
      assert Enum.map(bookings, & &1.external_id) == [2, 1, 3]
    end
  end
end
