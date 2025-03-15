defmodule SchedshareWeb.Plugs.EnsureAdmin do
  @moduledoc """
  This plug ensures that a user is an admin.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Schedshare.Accounts.User
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    Logger.debug("EnsureAdmin plug called")
    Logger.debug("Current user: #{inspect(conn.assigns.current_user)}")

    case conn.assigns.current_user do
      %User{} = user ->
        Logger.debug("User found: #{user.email}, is_admin: #{user.is_admin}")
        if User.is_admin?(user) do
          Logger.debug("User is admin, allowing access")
          conn
        else
          Logger.debug("User is not admin, denying access")
          conn
          |> put_flash(:error, "You must be an admin to access this page.")
          |> redirect(to: "/")
          |> halt()
        end

      _ ->
        Logger.debug("No user found in conn.assigns")
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/users/log_in")
        |> halt()
    end
  end
end
