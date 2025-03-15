defmodule SchedshareWeb.ProfileLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Accounts

  def mount(%{"id" => user_id}, _session, socket) do
    if socket.assigns[:current_user] do
      user = Accounts.get_user!(user_id)
      followers = Accounts.get_followers(user.id)
      following = Accounts.get_following(user.id)
      pending_requests = Accounts.get_pending_follow_requests(user.id)

      # Check if current user has a pending follow request or is already following
      follow = Accounts.get_follow(socket.assigns.current_user.id, user.id)
      is_following = follow && follow.status == :approved
      has_pending_request = follow && follow.status == :pending

      is_self = socket.assigns.current_user.id == user.id
      is_admin = Accounts.is_admin?(socket.assigns.current_user)

      {:ok,
       assign(socket,
         page_title: "Profile - #{user.email}",
         user: user,
         followers: followers,
         following: following,
         pending_requests: pending_requests,
         is_following: is_following,
         has_pending_request: has_pending_request,
         is_self: is_self,
         is_admin: is_admin
       )}
    else
      {:ok, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      user = socket.assigns.current_user
      followers = Accounts.get_followers(user.id)
      following = Accounts.get_following(user.id)
      pending_requests = Accounts.get_pending_follow_requests(user.id)
      is_admin = Accounts.is_admin?(socket.assigns.current_user)

      {:ok,
       assign(socket,
         page_title: "My Profile",
         user: user,
         followers: followers,
         following: following,
         pending_requests: pending_requests,
         is_self: true,
         is_admin: is_admin
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

  def handle_event("follow", _, socket) do
    case Accounts.create_follow(socket.assigns.current_user.id, socket.assigns.user.id) do
      {:ok, _follow} ->
        {:noreply,
         socket
         |> put_flash(:info, "Follow request sent!")
         |> assign(has_pending_request: true)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to send follow request")}
    end
  end

  def handle_event("unfollow", _, socket) do
    with follow <- Accounts.get_follow(socket.assigns.current_user.id, socket.assigns.user.id),
         {:ok, _} <- Accounts.delete_follow(follow.id) do
      # Update followers list if we were in their followers
      followers = Enum.reject(socket.assigns.followers, fn f -> f.follower_id == socket.assigns.current_user.id end)

      {:noreply,
       socket
       |> assign(is_following: false, has_pending_request: false, followers: followers)
       |> put_flash(:info, "Unfollowed successfully")}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to unfollow user")}
    end
  end

  def handle_event("approve_request", %{"id" => follow_id}, socket) do
    case Accounts.approve_follow(follow_id) do
      {:ok, follow} ->
        pending_requests = Enum.reject(socket.assigns.pending_requests, &(&1.id == follow.id))
        followers = [follow | socket.assigns.followers]

        {:noreply,
         socket
         |> assign(pending_requests: pending_requests, followers: followers)
         |> put_flash(:info, "Follow request approved!")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to approve request")}
    end
  end

  def handle_event("reject_request", %{"id" => follow_id}, socket) do
    case Accounts.delete_follow(follow_id) do
      {:ok, follow} ->
        pending_requests = Enum.reject(socket.assigns.pending_requests, &(&1.id == follow.id))

        {:noreply,
         socket
         |> assign(pending_requests: pending_requests)
         |> put_flash(:info, "Follow request rejected")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to reject request")}
    end
  end
end
