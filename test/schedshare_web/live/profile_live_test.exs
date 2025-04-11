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

  # Helper to check for text in HTML elements
  defp html_element(view, selector, text) when is_binary(text) do
    view |> element(selector, text) |> has_element?()
  end

  defp html_element(view, selector, text_pattern) when is_struct(text_pattern, Regex) do
    view |> element(selector, text_pattern) |> has_element?()
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
      assert html_element(view, "h3", "Vinyasa Recharge • EN")
      assert view |> element("p", ~r/YOGA at Lobe Block/) |> has_element?()
      assert view |> element("p", ~r/Ulrike/) |> has_element?()
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

  describe "Going together feature" do
    setup %{conn: conn} do
      # Create three users for our tests
      user1 = create_user(%{email: "user1@example.com"})
      user2 = create_user(%{email: "user2@example.com"})
      user3 = create_user(%{email: "user3@example.com"})

      # Confirm all users by updating the confirmed_at directly
      # (since we don't have tokens in the test environment)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      {:ok, user1} = Schedshare.Repo.update(Ecto.Changeset.change(user1, confirmed_at: now))
      {:ok, user2} = Schedshare.Repo.update(Ecto.Changeset.change(user2, confirmed_at: now))
      {:ok, user3} = Schedshare.Repo.update(Ecto.Changeset.change(user3, confirmed_at: now))

      # Create follows between all users and approve them
      {:ok, follow1} = Accounts.create_follow(user1.id, user2.id)
      {:ok, follow2} = Accounts.create_follow(user1.id, user3.id)
      {:ok, follow3} = Accounts.create_follow(user2.id, user3.id)
      {:ok, follow4} = Accounts.create_follow(user2.id, user1.id)
      {:ok, follow5} = Accounts.create_follow(user3.id, user1.id)
      {:ok, follow6} = Accounts.create_follow(user3.id, user2.id)

      {:ok, _} = Accounts.approve_follow(follow1.id)
      {:ok, _} = Accounts.approve_follow(follow2.id)
      {:ok, _} = Accounts.approve_follow(follow3.id)
      {:ok, _} = Accounts.approve_follow(follow4.id)
      {:ok, _} = Accounts.approve_follow(follow5.id)
      {:ok, _} = Accounts.approve_follow(follow6.id)

      # Create schedules for all users
      schedule1 = create_schedule(user1)
      schedule2 = create_schedule(user2)
      schedule3 = create_schedule(user3)

      # Create a shared yoga class for user1 and user2
      {:ok, yoga_booking1} = Scheduling.create_booking(%{
        schedule_id: schedule1.id,
        external_id: 101,
        course_external_id: 1001,
        status: "CONFIRMED",
        course_title: "Yoga Flow",
        start_datetime_utc: ~U[2025-03-17 10:00:00Z],
        end_datetime_utc: ~U[2025-03-17 11:00:00Z],
        venue_name: "Yoga Studio",
        teacher_name: "Sarah",
        course_types: ["yoga", "beginner"]
      })

      {:ok, yoga_booking2} = Scheduling.create_booking(%{
        schedule_id: schedule2.id,
        external_id: 102,
        course_external_id: 1001,  # Same course_external_id as yoga_booking1
        status: "CONFIRMED",
        course_title: "Yoga Flow",
        start_datetime_utc: ~U[2025-03-17 10:00:00Z],
        end_datetime_utc: ~U[2025-03-17 11:00:00Z],
        venue_name: "Yoga Studio",
        teacher_name: "Sarah",
        course_types: ["yoga", "beginner"]
      })

      # Create a HIIT class only for user3
      {:ok, hiit_booking} = Scheduling.create_booking(%{
        schedule_id: schedule3.id,
        external_id: 103,
        course_external_id: 1002,
        status: "CONFIRMED",
        course_title: "HIIT Training",
        start_datetime_utc: ~U[2025-03-18 14:00:00Z],
        end_datetime_utc: ~U[2025-03-18 15:00:00Z],
        venue_name: "Fitness Center",
        teacher_name: "Mike",
        course_types: ["hiit", "advanced"]
      })

      %{
        conn: log_in_user(conn, user1),
        user1: user1,
        user2: user2,
        user3: user3,
        schedule1: schedule1,
        schedule2: schedule2,
        schedule3: schedule3,
        yoga_booking1: yoga_booking1,
        yoga_booking2: yoga_booking2,
        hiit_booking: hiit_booking
      }
    end

    test "shows 'You're going together' when viewing profile of user with shared class", %{conn: conn, user2: user2} do
      {:ok, view, _html} = live(conn, ~p"/profile/#{user2.id}")

      # Check if text containing "going together" appears on the page
      assert view |> element("p", ~r/going together/) |> has_element?()

      # Make sure the message is associated with the Yoga class
      html = render(view)
      assert html =~ "Yoga Flow"
      assert html =~ "going together"
    end

    test "doesn't show 'You're going together' when not in the same class", %{conn: conn, user3: user3} do
      {:ok, view, _html} = live(conn, ~p"/profile/#{user3.id}")

      # Verify the HIIT class appears
      assert html_element(view, "h3", "HIIT Training")

      # Check that "going together" doesn't appear
      refute view |> element("p", ~r/going together/) |> has_element?()
    end

    test "shows 'Going with:' on own profile when others are in the same class", %{conn: conn, user1: user1} do
      {:ok, view, _html} = live(conn, ~p"/profile/#{user1.id}")

      # Check if "Going with:" appears
      assert view |> element("p", ~r/Going with/) |> has_element?()

      # Check if user2's email appears in the list
      html = render(view)
      assert html =~ "user2@example.com"
    end

    test "switching users shows correct shared class information", %{conn: conn, user1: user1, user2: user2, user3: user3} do
      # Log in as user2 now
      conn = log_in_user(conn, user2)

      # Visit user1's profile - should show "You're going together"
      {:ok, view, _html} = live(conn, ~p"/profile/#{user1.id}")
      assert view |> element("p", ~r/going together/) |> has_element?()

      # Visit user3's profile - should NOT show "You're going together"
      {:ok, view, _html} = live(conn, ~p"/profile/#{user3.id}")
      refute view |> element("p", ~r/going together/) |> has_element?()

      # Now log in as user3
      conn = log_in_user(conn, user3)

      # Visit user1's profile - should NOT show "You're going together"
      {:ok, view, _html} = live(conn, ~p"/profile/#{user1.id}")
      refute view |> element("p", ~r/going together/) |> has_element?()
    end
  end

  describe "Profile schedules" do
    test "shows user's schedule when viewing own profile", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a schedule with a sports course
      {:ok, schedule} = Schedshare.Scheduling.create_schedule(user, %{name: "My Schedule"})
      now = DateTime.utc_now()
      tomorrow = DateTime.add(now, 24 * 60 * 60, :second)

      {:ok, course} = Schedshare.Scheduling.create_course(%{
        course_title: "Vinyasa Flow Yoga",
        course_external_id: 101,
        start_datetime_utc: tomorrow,
        end_datetime_utc: DateTime.add(tomorrow, 1 * 60 * 60, :second),
        venue_name: "Zen Studio",
        venue_full_address: "123 Peace St, Berlin",
        teacher_name: "Sarah"
      })

      {:ok, _booking} = Schedshare.Scheduling.create_booking(schedule, course)

      {:ok, _lv, html} = live(conn, ~p"/profiles/#{user.id}")
      assert html =~ "My Schedule"
      assert html =~ "Vinyasa Flow Yoga"
      assert html =~ "Zen Studio"
    end

    test "shows friend's schedule when friends", %{conn: conn} do
      user = user_fixture()
      friend = user_fixture()
      conn = log_in_user(conn, user)

      # Create friendship
      {:ok, _friendship} = Schedshare.Accounts.create_friendship(user.id, friend.id)
      {:ok, _friendship} = Schedshare.Accounts.accept_friendship(friend.id, user.id)

      # Create friend's schedule with a sports course
      {:ok, schedule} = Schedshare.Scheduling.create_schedule(friend, %{name: "Friend's Schedule"})
      now = DateTime.utc_now()
      tomorrow = DateTime.add(now, 24 * 60 * 60, :second)

      {:ok, course} = Schedshare.Scheduling.create_course(%{
        course_title: "HIIT Training",
        course_external_id: 201,
        start_datetime_utc: tomorrow,
        end_datetime_utc: DateTime.add(tomorrow, 1 * 60 * 60, :second),
        venue_name: "Power Gym",
        venue_full_address: "456 Energy Ave, Berlin",
        teacher_name: "Mike"
      })

      {:ok, _booking} = Schedshare.Scheduling.create_booking(schedule, course)

      {:ok, _lv, html} = live(conn, ~p"/profiles/#{friend.id}")
      assert html =~ "Friend's Schedule"
      assert html =~ "HIIT Training"
      assert html =~ "Power Gym"
    end

    test "hides non-friend's schedule", %{conn: conn} do
      user = user_fixture()
      stranger = user_fixture()
      conn = log_in_user(conn, user)

      # Create stranger's schedule
      {:ok, schedule} = Schedshare.Scheduling.create_schedule(stranger, %{name: "Stranger's Schedule"})
      now = DateTime.utc_now()
      tomorrow = DateTime.add(now, 24 * 60 * 60, :second)

      {:ok, course} = Schedshare.Scheduling.create_course(%{
        course_title: "Pilates Core",
        course_external_id: 301,
        start_datetime_utc: tomorrow,
        end_datetime_utc: DateTime.add(tomorrow, 1 * 60 * 60, :second),
        venue_name: "Core Studio",
        venue_full_address: "789 Balance St, Berlin",
        teacher_name: "Lisa"
      })

      {:ok, _booking} = Schedshare.Scheduling.create_booking(schedule, course)

      {:ok, _lv, html} = live(conn, ~p"/profiles/#{stranger.id}")
      refute html =~ "Stranger's Schedule"
      refute html =~ "Pilates Core"
    end
  end
end
