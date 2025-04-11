defmodule SchedshareWeb.IndexLiveTest do
  use SchedshareWeb.ConnCase

  import Phoenix.LiveViewTest
  import Schedshare.AccountsFixtures

  setup do
    Application.put_env(:schedshare, :dev_routes, true)
    :ok
  end

  describe "Index page" do
    test "renders landing page when not logged in", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "SchedShare"
      assert html =~ "Share and sync your sports class schedules with friends"
      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "Welcome back"
      assert html =~ user.email
    end
  end

  describe "Welcome message" do
    test "displays user's name when available", %{conn: conn} do
      user = user_fixture(%{name: "Test User"})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "Welcome back, Test User!"
    end

    test "falls back to email when name is not set", %{conn: conn} do
      user = user_fixture(%{name: nil})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "Welcome back, #{user.email}!"
    end

    test "shows profile link for logged in users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/")

      assert has_element?(lv, ~s|a[href="/profile"]|, "View my schedule")
      assert has_element?(lv, ".text-emerald-600", "View my schedule")
    end
  end

  describe "Admin features" do
    test "shows admin tools for admin users", %{conn: conn} do
      {:ok, user} = Schedshare.Accounts.register_user(%{email: "admin@example.com", password: "adminpassword123"})
      {:ok, admin} = Schedshare.Accounts.update_user_admin(user, %{is_admin: true})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Admin Tools"
      assert html =~ "Users"
      assert html =~ "LiveDashboard"
      assert html =~ "Email Preview"
    end

    test "hides admin tools for regular users", %{conn: conn} do
      user = user_fixture(%{is_admin: false})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/")

      refute html =~ "Admin Tools"
      refute html =~ "Users"
      refute html =~ "LiveDashboard"
      refute html =~ "Email Preview"
    end
  end

  describe "Friend requests" do
    test "shows pending friend requests section when requests exist", %{conn: conn} do
      user = user_fixture()
      friend = user_fixture()
      {:ok, _friendship} = Schedshare.Accounts.create_friendship(friend.id, user.id)

      conn = log_in_user(conn, user)
      {:ok, lv, html} = live(conn, ~p"/")

      assert html =~ "Pending Friend Requests"
      assert has_element?(lv, "button", "Accept")
      assert has_element?(lv, "button", "Reject")
      assert html =~ friend.email

      # Test approving a request
      assert lv
             |> element("button", "Accept")
             |> render_click() =~ "Friend request accepted"

      # Verify the request is removed from the list
      refute render(lv) =~ friend.email
    end

    test "handles friend request rejection", %{conn: conn} do
      user = user_fixture()
      friend = user_fixture()
      {:ok, _friendship} = Schedshare.Accounts.create_friendship(friend.id, user.id)

      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/")

      # Test rejecting a request
      assert lv
             |> element("button", "Reject")
             |> render_click() =~ "Friend request rejected"

      # Verify the request is removed from the list
      refute render(lv) =~ friend.email
    end

    test "hides pending friend requests section when no requests exist", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/")
      refute html =~ "Pending Friend Requests"
    end
  end
end
