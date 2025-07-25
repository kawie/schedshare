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
      schedules = Scheduling.list_user_schedules(user.id)
      assert length(schedules) == 1
      assert hd(schedules).id == schedule.id
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

  describe "sync_waitlist_items/2" do
    test "creates new waitlist items" do
      user = user_fixture()
      schedule = schedule_fixture(user)

      waitlist_items = [
        %{
          "id" => 123,
          "course_external_id" => 123,
          "title" => "Yoga Class",
          "start_time" => "2025-01-15T10:00:00Z",
          "end_time" => "2025-01-15T11:00:00Z",
          "location" => "Yoga Studio",
          "teacher_name" => "Jane Doe",
          "course_types" => ["onsite"],
          "is_online" => false
        }
      ]

      assert {:ok, _} = Scheduling.sync_waitlist_items(user.id, waitlist_items)

      # Check that the waitlist item was created
      bookings = Scheduling.list_schedule_bookings(schedule.id)
      assert length(bookings) == 1

      booking = hd(bookings)
      assert booking.status == "WAITLISTED"
      assert booking.course_title == "Yoga Class"
      assert booking.course_external_id == 123
      assert booking.venue_name == "Yoga Studio"
      assert booking.teacher_name == "Jane Doe"
    end

    test "updates existing waitlist items" do
      user = user_fixture()
      schedule = schedule_fixture(user)

      # Create an existing waitlist item
      existing_booking = booking_fixture(schedule, %{
        external_id: 123,
        course_external_id: 123,
        status: "WAITLISTED",
        course_title: "Old Title",
        start_datetime_utc: ~U[2025-01-15 10:00:00Z],
        end_datetime_utc: ~U[2025-01-15 11:00:00Z],
        venue_name: "Old Studio",
        teacher_name: "Old Teacher"
      })

      # Update the waitlist item
      waitlist_items = [
        %{
          "id" => 123,
          "course_external_id" => 123,
          "title" => "New Title",
          "start_time" => "2025-01-15T10:00:00Z",
          "end_time" => "2025-01-15T11:00:00Z",
          "location" => "New Studio",
          "teacher_name" => "New Teacher",
          "course_types" => ["onsite"],
          "is_online" => false
        }
      ]

      assert {:ok, _} = Scheduling.sync_waitlist_items(user.id, waitlist_items)

      # Check that the waitlist item was updated
      updated_booking = Scheduling.get_booking!(existing_booking.id)
      assert updated_booking.course_title == "New Title"
      assert updated_booking.venue_name == "New Studio"
      assert updated_booking.teacher_name == "New Teacher"
      assert updated_booking.status == "WAITLISTED"
    end

    test "marks waitlist items as deleted when removed from waitlist" do
      user = user_fixture()
      schedule = schedule_fixture(user)

      # Create an existing waitlist item
      existing_booking = booking_fixture(schedule, %{
        external_id: 123,
        course_external_id: 123,
        status: "WAITLISTED",
        course_title: "Yoga Class",
        start_datetime_utc: ~U[2025-01-15 10:00:00Z],
        end_datetime_utc: ~U[2025-01-15 11:00:00Z],
        venue_name: "Yoga Studio",
        teacher_name: "Jane Doe"
      })

      # Sync with empty waitlist (item was removed)
      assert {:ok, _} = Scheduling.sync_waitlist_items(user.id, [])

      # Check that the waitlist item was marked as deleted
      updated_booking = Scheduling.get_booking!(existing_booking.id)
      assert updated_booking.status == "DELETED"
    end

    test "handles transition from waitlisted to confirmed" do
      user = user_fixture()
      schedule = schedule_fixture(user)

      # Create a waitlist item
      waitlist_booking = booking_fixture(schedule, %{
        external_id: 123,
        course_external_id: 123,
        status: "WAITLISTED",
        course_title: "Yoga Class",
        start_datetime_utc: ~U[2025-01-15 10:00:00Z],
        end_datetime_utc: ~U[2025-01-15 11:00:00Z],
        venue_name: "Yoga Studio",
        teacher_name: "Jane Doe"
      })

      # Now sync with the same item as a confirmed booking
      confirmed_bookings = [
        %{
          "id" => 456, # Different ID since it's now a confirmed booking
          "course_external_id" => 123,
          "title" => "Yoga Class",
          "start_time" => "2025-01-15T10:00:00Z",
          "end_time" => "2025-01-15T11:00:00Z",
          "location" => "Yoga Studio",
          "teacher_name" => "Jane Doe",
          "course_types" => ["onsite"],
          "is_online" => false,
          "status" => "CONFIRMED"
        }
      ]

      # Sync regular bookings first
      assert {:ok, _} = Scheduling.sync_bookings(user.id, confirmed_bookings)

      # Then sync waitlist (which should be empty now)
      assert {:ok, _} = Scheduling.sync_waitlist_items(user.id, [])

      # Check that the waitlist item was marked as deleted
      updated_waitlist_booking = Scheduling.get_booking!(waitlist_booking.id)
      assert updated_waitlist_booking.status == "DELETED"

      # Check that the confirmed booking was created
      bookings = Scheduling.list_schedule_bookings(schedule.id)
      confirmed_bookings = Enum.filter(bookings, &(&1.status == "CONFIRMED"))
      assert length(confirmed_bookings) == 1

      confirmed_booking = hd(confirmed_bookings)
      assert confirmed_booking.course_external_id == 123
      assert confirmed_booking.course_title == "Yoga Class"
    end
  end
end
