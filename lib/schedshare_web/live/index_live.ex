defmodule SchedshareWeb.IndexLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Accounts
  alias Schedshare.Scheduling
  alias SchedshareWeb.Live.Components.PendingRequestsComponent
  alias SchedshareWeb.Live.Components.RecentBookingsComponent
  alias SchedshareWeb.Live.Components.AdminUsersComponent
  alias SchedshareWeb.Live.Components.WelcomeSectionComponent

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the link"
  attr :variant, :atom, default: :default, values: [:default, :primary]
  slot :inner_block, required: true
  def styled_link(assigns) do
    ~H"""
    <.link
      {@rest}
      class={[
        "text-sm font-semibold leading-6",
        @variant == :primary && "text-interactive-primary-light dark:text-interactive-primary-dark hover:text-interactive-primary-light/80 dark:hover:text-interactive-primary-dark/80",
        @variant == :default && "text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80"
      ]}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

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
    <div class="h-full bg-background-light dark:bg-background-dark">
      <div class="mx-auto max-w-2xl py-4 px-4 sm:px-6 lg:px-8">
        <div class="">
          <%= if @current_user do %>
            <div class="mt-10">
              <h2 class="text-2xl font-semibold text-text-primary-light dark:text-text-primary-dark">
                Welcome back, <%= @current_user.name || @current_user.email %>!
              </h2>

              <div class="mt-4 flex flex-col gap-4">
                <.styled_link navigate={~p"/profile"} variant={:primary}>
                  View my schedule →
                </.styled_link>

                <.styled_link navigate={~p"/calendar"}>
                  View calendar →
                </.styled_link>

                <.styled_link navigate="/users/settings">
                  Settings →
                </.styled_link>

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
                    <div class="mt-6 border-t border-border-light dark:border-border-dark pt-6">
                      <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">Admin Tools</h3>
                      <div class="mt-4 flex flex-col gap-3">
                        <.styled_link navigate="/admin/dashboard">
                          LiveDashboard →
                        </.styled_link>
                        <.styled_link navigate="/admin/errors">
                          Error Tracker →
                        </.styled_link>
                        <%= if Application.get_env(:schedshare, :dev_routes) do %>
                          <.styled_link navigate="/dev/mailbox">
                            Email Preview →
                          </.styled_link>
                        <% end %>

                        <.live_component
                          module={AdminUsersComponent}
                          id="admin-users"
                          users={@users}
                        />
                      </div>
                    </div>
                  <% end %>

                  <.styled_link href="/users/log_out" method="delete">
                    Log out →
                  </.styled_link>
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
