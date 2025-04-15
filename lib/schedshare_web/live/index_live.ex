defmodule SchedshareWeb.IndexLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Accounts
  alias Schedshare.Scheduling
  alias SchedshareWeb.Live.Components.PendingRequestsComponent
  alias SchedshareWeb.Live.Components.RecentBookingsComponent
  alias SchedshareWeb.Live.Components.AdminUsersComponent
  alias SchedshareWeb.Live.Components.WelcomeSectionComponent

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      pending_requests = Accounts.get_pending_friend_requests(socket.assigns.current_user.id)
      recent_bookings = Scheduling.list_recent_friend_bookings(socket.assigns.current_user.id)
      users =
        if Accounts.is_admin?(socket.assigns.current_user) do
          Accounts.list_users()
          |> Enum.map(fn user ->
            credential = Scheduling.get_user_api_credential(user.id)
            %{
              user: user,
              has_credentials: not is_nil(credential),
              last_sync: if(credential, do: credential.last_sync_at, else: nil)
            }
          end)
        else
          []
        end
      {:ok, assign(socket, page_title: "SchedShare", users: users, pending_requests: pending_requests, recent_bookings: recent_bookings)}
    else
      {:ok, assign(socket, page_title: "SchedShare")}
    end
  end

  def handle_event("accept_request", %{"id" => id}, socket) do
    case Accounts.accept_friendship(id) do
      {:ok, _friendship} ->
        pending_requests = Accounts.get_pending_friend_requests(socket.assigns.current_user.id)
        {:noreply, socket |> assign(pending_requests: pending_requests) |> put_flash(:info, "Friend request accepted")}
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Unable to accept friend request")}
    end
  end

  def handle_event("reject_request", %{"id" => id}, socket) do
    case Accounts.delete_friendship(id) do
      {:ok, _} ->
        pending_requests = Accounts.get_pending_friend_requests(socket.assigns.current_user.id)
        {:noreply, socket |> assign(pending_requests: pending_requests) |> put_flash(:info, "Friend request rejected")}
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Unable to reject friend request")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="h-full bg-white">
      <div class="mx-auto max-w-2xl py-4 px-4 sm:px-6 lg:px-8">
        <div class="">
          <%= if @current_user do %>
            <div class="mt-10">
              <h2 class="text-2xl font-semibold text-zinc-900">
                Welcome back, <%= @current_user.name || @current_user.email %>!
              </h2>

              <div class="mt-4 flex flex-col gap-4">
                <.link
                  navigate={~p"/profile"}
                  class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                >
                  View my schedule →
                </.link>

                <.link
                  navigate={~p"/calendar"}
                  class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                >
                  View calendar →
                </.link>

                <.link
                    navigate="/users/settings"
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    Settings →
                </.link>

                <.live_component
                  module={PendingRequestsComponent}
                  id="pending-requests"
                  pending_requests={@pending_requests}
                />

                <.live_component
                  module={RecentBookingsComponent}
                  id="recent-bookings"
                  recent_bookings={@recent_bookings}
                />

                <div class="mt-4 flex flex-col gap-4">
                  <%= if Accounts.is_admin?(@current_user) do %>
                    <div class="mt-6 border-t border-zinc-200 pt-6">
                      <h3 class="text-lg font-semibold text-zinc-900">Admin Tools</h3>
                      <div class="mt-4 flex flex-col gap-3">
                        <.link
                          navigate="/admin/dashboard"
                          class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                        >
                          LiveDashboard →
                        </.link>
                        <.link
                          navigate="/admin/errors"
                          class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                        >
                          Error Tracker →
                        </.link>
                        <%= if Application.get_env(:schedshare, :dev_routes) do %>
                          <.link
                            navigate="/dev/mailbox"
                            class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                          >
                            Email Preview →
                          </.link>
                        <% end %>

                        <.live_component
                          module={AdminUsersComponent}
                          id="admin-users"
                          users={@users}
                        />
                      </div>
                    </div>
                  <% end %>

                  <.link
                    href="/users/log_out"
                    method="delete"
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    Log out →
                  </.link>
                </div>
              </div>
            </div>
          <% else %>
            <.live_component
              module={WelcomeSectionComponent}
              id="welcome-section"
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
