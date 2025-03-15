defmodule SchedshareWeb.Plugs.EnsureAdminTest do
  use SchedshareWeb.ConnCase, async: true

  alias SchedshareWeb.Plugs.EnsureAdmin
  alias Schedshare.Accounts

  describe "ensure_admin plug" do
    test "allows access when user is admin", %{conn: conn} do
      user = %{email: "admin@example.com", password: "adminpassword123"}
      {:ok, user} = Accounts.register_user(user)
      {:ok, user} = Accounts.update_user_admin(user, %{is_admin: true})

      conn =
        conn
        |> assign(:current_user, user)
        |> EnsureAdmin.call(%{})

      refute conn.halted
    end

    test "redirects when user is not admin", %{conn: conn} do
      user = %{email: "user@example.com", password: "userpassword123"}
      {:ok, user} = Accounts.register_user(user)

      conn =
        conn
        |> assign(:current_user, user)
        |> EnsureAdmin.call(%{})

      assert conn.halted
      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must be an admin"
    end

    test "redirects when no user is logged in", %{conn: conn} do
      conn = EnsureAdmin.call(conn, %{})

      assert conn.halted
      assert redirected_to(conn) == "/users/log_in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must be logged in"
    end
  end
end
