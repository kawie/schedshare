defmodule SchedshareWeb.ProfileLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Accounts
  alias Schedshare.Scheduling
  alias Schedshare.Scheduling.ApiCredential
  alias SchedshareWeb.DatetimeHelper

  def mount(%{"id" => user_id}, _session, socket) do
    if socket.assigns[:current_user] do
      user = Accounts.get_user!(user_id)
      friends = Accounts.get_friends(user.id)

      # Check if current user has a pending friend request or is already friends
      friendship = Accounts.get_friendship(socket.assigns.current_user.id, user.id)
      is_friend = friendship && friendship.status == :accepted
      has_pending_request = friendship && friendship.status == :pending

      is_self = socket.assigns.current_user.id == user.id
      is_admin = Accounts.is_admin?(socket.assigns.current_user)

      # Load schedule and bookings if user is self or a friend
      schedule_with_bookings =
        if is_self || is_friend do
          case Scheduling.list_user_schedules(user.id) do
            [schedule] ->
              # Filter out deleted bookings
              %{schedule | bookings: Enum.reject(schedule.bookings, &(&1.status == "DELETED"))}
            _ -> nil
          end
        else
          nil
        end

      # Get other users in the same courses
      other_users_in_course =
        if schedule_with_bookings do
          schedule_with_bookings.bookings
          |> Enum.map(fn booking ->
            {booking.id, Scheduling.get_users_in_same_course(booking, socket.assigns.current_user.id)}
          end)
          |> Map.new()
        else
          %{}
        end

      # Load API credentials if user is self
      api_credential = if is_self, do: Scheduling.get_user_api_credential(user.id), else: nil
      api_credential_changeset = if is_self, do: Scheduling.change_api_credential(api_credential || %ApiCredential{}), else: nil
      has_credentials = if is_self, do: not is_nil(api_credential), else: false
      last_sync = if api_credential, do: api_credential.last_sync_at, else: nil

      {:ok,
       assign(socket,
         page_title: "#{user.name || user.email} - Profile",
         user: user,
         friends: friends,
         is_friend: is_friend,
         has_pending_request: has_pending_request,
         is_self: is_self,
         is_admin: is_admin,
         schedule: schedule_with_bookings,
         other_users_in_course: other_users_in_course,
         api_credential: api_credential,
         api_credential_changeset: api_credential_changeset,
         has_credentials: has_credentials,
         last_sync: last_sync,
         calendar_url: "/profile/#{user.id}/calendar.ics?token=#{user.calendar_token}"
       )}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      user = socket.assigns.current_user
      friends = Accounts.get_friends(user.id)
      is_admin = Accounts.is_admin?(socket.assigns.current_user)

      # Load own schedule and bookings
      schedule_with_bookings =
        case Scheduling.list_user_schedules(user.id) do
          [schedule] ->
            # Filter out deleted bookings
            %{schedule | bookings: Enum.reject(schedule.bookings, &(&1.status == "DELETED"))}
          _ -> nil
        end

      # Get other users in the same courses
      other_users_in_course =
        if schedule_with_bookings do
          schedule_with_bookings.bookings
          |> Enum.map(fn booking ->
            {booking.id, Scheduling.get_users_in_same_course(booking, socket.assigns.current_user.id)}
          end)
          |> Map.new()
        else
          %{}
        end

      # Load API credentials
      api_credential = Scheduling.get_user_api_credential(user.id)
      api_credential_changeset = Scheduling.change_api_credential(api_credential || %ApiCredential{})
      has_credentials = not is_nil(api_credential)
      last_sync = if api_credential, do: api_credential.last_sync_at, else: nil

      {:ok,
       assign(socket,
         page_title: "My Profile",
         user: user,
         friends: friends,
         is_self: true,
         is_admin: is_admin,
         schedule: schedule_with_bookings,
         other_users_in_course: other_users_in_course,
         api_credential: api_credential,
         api_credential_changeset: api_credential_changeset,
         has_credentials: has_credentials,
         last_sync: last_sync
       )}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  def handle_event("make_admin", _, socket) do
    if Accounts.is_admin?(socket.assigns.current_user) and not socket.assigns.is_self do
      case Accounts.update_user_admin(socket.assigns.user, %{is_admin: true}) do
        {:ok, user} ->
          {:noreply,
           socket
           |> assign(user: user)
           |> put_flash(:info, "User is now an admin")}

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Unable to update admin status")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Not authorized to perform this action")}
    end
  end

  def handle_event("remove_admin", _, socket) do
    if Accounts.is_admin?(socket.assigns.current_user) and not socket.assigns.is_self do
      case Accounts.update_user_admin(socket.assigns.user, %{is_admin: false}) do
        {:ok, user} ->
          {:noreply,
           socket
           |> assign(user: user)
           |> put_flash(:info, "Admin status removed")}

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Unable to update admin status")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Not authorized to perform this action")}
    end
  end

  def handle_event("add_friend", _, socket) do
    case Accounts.create_friendship(socket.assigns.current_user.id, socket.assigns.user.id) do
      {:ok, _friendship} ->
        {:noreply,
         socket
         |> put_flash(:info, "Friend request sent!")
         |> assign(has_pending_request: true)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to send friend request")}
    end
  end

  def handle_event("remove_friend", _, socket) do
    with friendship <- Accounts.get_friendship(socket.assigns.current_user.id, socket.assigns.user.id),
         {:ok, _} <- Accounts.delete_friendship(friendship.id) do
      {:noreply,
       socket
       |> assign(is_friend: false, has_pending_request: false)
       |> put_flash(:info, "Friend removed successfully")}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to remove friend")}
    end
  end
end
