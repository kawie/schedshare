defmodule SchedshareWeb.ProfileLiveTest do
  use SchedshareWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Schedshare.{Accounts, Scheduling}

  @valid_user_attrs %{email: "test@example.com", password: "hello world!"}
  @other_user_attrs %{email: "other@example.com", password: "hello world!"}

  defp create_user(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_user_attrs)
      |> Accounts.register_user()

    user
  end

  defp create_other_user(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@other_user_attrs)
      |> Accounts.register_user()

    user
  end

  defp create_schedule(user) do
    {:ok, schedule} = Scheduling.create_schedule(%{user_id: user.id})
    schedule
  end

  defp create_booking(schedule) do
    {:ok, booking} = Scheduling.create_booking(%{
      schedule_id: schedule.id,
      external_id: 76428995,
      status: "CONFIRMED",
      course_title: "Vinyasa Recharge • EN",
      start_datetime_utc: ~U[2025-03-24 15:30:00Z],
      end_datetime_utc: ~U[2025-03-24 16:30:00Z],
      venue_name: "YOGA at Lobe Block",
      teacher_name: "Ulrike",
      course_types: ["onsite"]
    })
    booking
  end

  describe "Profile Schedule" do
    setup %{conn: conn} do
      user = create_user()
      other_user = create_other_user()
      schedule = create_schedule(other_user)
      booking = create_booking(schedule)

      %{
        conn: log_in_user(conn, user),
        user: user,
        other_user: other_user,
        schedule: schedule,
        booking: booking
      }
    end

    test "shows no schedule section when not following", %{conn: conn, other_user: other_user} do
      {:ok, view, _html} = live(conn, ~p"/profile/#{other_user.id}")
      refute has_element?(view, "[data-test-id='schedule-section']")
    end

    test "shows schedule section with no bookings for own profile", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/profile/#{user.id}")
      assert has_element?(view, "[data-test-id='schedule-section']")
      assert has_element?(view, "[data-test-id='no-schedule-warning']")
    end

    test "shows schedule with bookings when following", %{conn: conn, user: user, other_user: other_user} do
      # Create and approve follow request
      {:ok, follow} = Accounts.create_follow(user.id, other_user.id)
      {:ok, _follow} = Accounts.approve_follow(follow.id)

      {:ok, view, _html} = live(conn, ~p"/profile/#{other_user.id}")

      assert has_element?(view, "[data-test-id='schedule-section']")
      assert has_element?(view, "[data-test-id='booking-list']")
      assert has_element?(view, ~r/Vinyasa Recharge • EN/)
      assert has_element?(view, ~r/YOGA at Lobe Block/)
      assert has_element?(view, ~r/Ulrike/)
    end

    test "hides schedule when follow request is pending", %{conn: conn, user: user, other_user: other_user} do
      # Create follow request but don't approve it
      {:ok, _follow} = Accounts.create_follow(user.id, other_user.id)

      {:ok, view, _html} = live(conn, ~p"/profile/#{other_user.id}")
      refute has_element?(view, "[data-test-id='schedule-section']")
    end

    test "shows schedule status indicators correctly", %{conn: conn, user: user, other_user: other_user, schedule: schedule} do
      # Create and approve follow request
      {:ok, follow} = Accounts.create_follow(user.id, other_user.id)
      {:ok, _follow} = Accounts.approve_follow(follow.id)

      # Create a cancelled booking
      {:ok, _} = Scheduling.create_booking(%{
        schedule_id: schedule.id,
        external_id: 76428996,
        status: "CANCELLED",
        course_title: "Cancelled Class",
        start_datetime_utc: ~U[2025-03-25 15:30:00Z],
        end_datetime_utc: ~U[2025-03-25 16:30:00Z],
        venue_name: "YOGA at Lobe Block",
        teacher_name: "Ulrike",
        course_types: ["onsite"]
      })

      {:ok, view, _html} = live(conn, ~p"/profile/#{other_user.id}")

      assert has_element?(view, "[data-test-id='status-confirmed']")
      assert has_element?(view, "[data-test-id='status-cancelled']")
    end
  end
end
