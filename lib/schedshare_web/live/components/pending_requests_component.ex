defmodule SchedshareWeb.Live.Components.PendingRequestsComponent do
  use SchedshareWeb, :live_component
  alias Schedshare.Accounts
  alias Phoenix.PubSub

  def mount(socket) do
    socket = if connected?(socket) and socket.assigns[:current_user] do
      # Subscribe to friend request updates for the current user
      PubSub.subscribe(Schedshare.PubSub, "friend_requests:#{socket.assigns.current_user.id}")
      # Ensure we have the initial list of pending requests
      assign(socket, pending_requests: socket.assigns.pending_requests || [])
    else
      assign(socket, pending_requests: [])
    end
    {:ok, socket}
  end

  def handle_info({:friend_request_created, request}, socket) do
    # Add the new request to the list if it's not already there
    if Enum.any?(socket.assigns.pending_requests, &(&1.id == request.id)) do
      {:noreply, socket}
    else
      {:noreply, assign(socket, pending_requests: [request | socket.assigns.pending_requests])}
    end
  end

  def handle_info({:friend_request_deleted, request_id}, socket) do
    # Remove the request from the list
    updated_requests = Enum.reject(socket.assigns.pending_requests, &(&1.id == request_id))
    {:noreply, assign(socket, pending_requests: updated_requests)}
  end

  def render(assigns) do
    ~H"""
    <div id={"pending-requests-#{@id}"}>
      <%= if length(@pending_requests) > 0 do %>
        <div class="mt-4">
          <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">Pending Friend Requests</h3>
          <div class="mt-2 divide-y divide-border-light dark:divide-border-dark">
            <%= for request <- @pending_requests do %>
              <div class="flex items-center justify-between py-3">
                <div class="flex items-center gap-3">
                  <%= if request.requested_by.profile_picture do %>
                    <img src={request.requested_by.profile_picture} alt={request.requested_by.name || request.requested_by.email} class="h-8 w-8 rounded-full" />
                  <% else %>
                    <div class="h-8 w-8 rounded-full bg-surface-light dark:bg-surface-dark flex items-center justify-center">
                      <.icon name="hero-user" class="w-4 h-4 text-text-secondary-light dark:text-text-secondary-dark" />
                    </div>
                  <% end %>
                  <div>
                    <div class="text-sm font-medium text-text-primary-light dark:text-text-primary-dark">
                      <%= request.requested_by.name || request.requested_by.email %>
                    </div>
                    <%= if request.requested_by.name do %>
                      <div class="text-xs text-text-secondary-light dark:text-text-secondary-dark">
                        <%= request.requested_by.email %>
                      </div>
                    <% end %>
                  </div>
                </div>
                <div class="flex gap-2">
                  <button
                    phx-click="accept_request"
                    phx-target={@myself}
                    phx-value-id={request.id}
                    class="rounded-md bg-status-successBg-light dark:bg-status-successBg-dark px-2.5 py-1.5 text-sm font-semibold text-status-success-light dark:text-status-success-dark shadow-sm hover:bg-status-successBg-light/80 dark:hover:bg-status-successBg-dark/80"
                  >
                    Accept
                  </button>
                  <button
                    phx-click="reject_request"
                    phx-target={@myself}
                    phx-value-id={request.id}
                    class="rounded-md bg-status-errorBg-light dark:bg-status-errorBg-dark px-2.5 py-1.5 text-sm font-semibold text-status-error-light dark:text-status-error-dark shadow-sm hover:bg-status-errorBg-light/80 dark:hover:bg-status-errorBg-dark/80"
                  >
                    Reject
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("accept_request", %{"id" => id}, socket) do
    case Accounts.accept_friendship(id) do
      {:ok, _friendship} ->
        pending_requests = Accounts.get_pending_friend_requests(socket.assigns.current_user.id)
        {:noreply, assign(socket, pending_requests: pending_requests)}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("reject_request", %{"id" => id}, socket) do
    case Accounts.delete_friendship(id) do
      {:ok, _} ->
        pending_requests = Accounts.get_pending_friend_requests(socket.assigns.current_user.id)
        {:noreply, assign(socket, pending_requests: pending_requests)}
      {:error, _} ->
        {:noreply, socket}
    end
  end
end
