defmodule SchedshareWeb.IndexLive do
  use SchedshareWeb, :live_view
  alias Schedshare.Accounts

  def mount(_params, _session, socket) do
    if socket.assigns[:current_user] do
      pending_requests = Accounts.get_pending_follow_requests(socket.assigns.current_user.id)
      users = if Accounts.is_admin?(socket.assigns.current_user), do: Accounts.list_users(), else: []
      {:ok, assign(socket, page_title: "SchedShare", users: users, pending_requests: pending_requests)}
    else
      {:ok, assign(socket, page_title: "SchedShare")}
    end
  end

  def handle_event("approve_request", %{"id" => follow_id}, socket) do
    case Accounts.approve_follow(follow_id) do
      {:ok, follow} ->
        pending_requests = Enum.reject(socket.assigns.pending_requests, &(&1.id == follow.id))
        {:noreply,
         socket
         |> assign(pending_requests: pending_requests)
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

  def render(assigns) do
    ~H"""
    <div class="h-full bg-white">
      <div class="mx-auto max-w-2xl py-16 px-4 sm:px-6 lg:px-8">
        <div class="">
          <h1 class="text-4xl font-bold tracking-tight text-zinc-900 sm:text-6xl">
            SchedShare
          </h1>
          <p class="mt-6 text-lg leading-8 text-zinc-600">
            Share and sync your sports class schedules with friends
          </p>

          <%= if @current_user do %>
            <div class="mt-10">
              <h2 class="text-2xl font-semibold text-zinc-900">
                Welcome back, <%= @current_user.email %>!
              </h2>

              <%= if length(@pending_requests) > 0 do %>
                <div class="mt-6 border-t border-zinc-200 pt-6">
                  <h3 class="text-lg font-semibold text-zinc-900">Pending Follow Requests</h3>
                  <div class="mt-4 divide-y divide-zinc-200">
                    <%= for request <- @pending_requests do %>
                      <div class="flex items-center justify-between py-4">
                        <div class="flex items-center">
                          <.link navigate={~p"/profile/#{request.follower.id}"} class="text-sm text-zinc-900 hover:text-zinc-700">
                            <%= request.follower.email %>
                          </.link>
                        </div>
                        <div class="flex space-x-2">
                          <button phx-click="approve_request" phx-value-id={request.id} class="rounded-md bg-emerald-600 px-2 py-1 text-xs font-semibold text-white shadow-sm hover:bg-emerald-500">
                            Approve
                          </button>
                          <button phx-click="reject_request" phx-value-id={request.id} class="rounded-md bg-zinc-600 px-2 py-1 text-xs font-semibold text-white shadow-sm hover:bg-zinc-500">
                            Reject
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="mt-4 flex flex-col gap-4">
                <.link
                  navigate="/users/settings"
                  class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  Settings →
                </.link>

                <%= if Accounts.is_admin?(@current_user) do %>
                  <div class="mt-6 border-t border-zinc-200 pt-6">
                    <h3 class="text-lg font-semibold text-zinc-900">Admin Tools</h3>
                    <div class="mt-4 flex flex-col gap-3">
                      <.link
                        navigate="/dev/dashboard"
                        class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                      >
                        LiveDashboard →
                      </.link>
                      <.link
                        navigate="/dev/mailbox"
                        class="text-sm font-semibold leading-6 text-emerald-600 hover:text-emerald-500"
                      >
                        Email Preview →
                      </.link>
                    </div>

                    <div class="mt-8">
                      <h3 class="text-lg font-semibold text-zinc-900">Users</h3>
                      <div class="mt-4 divide-y divide-zinc-200">
                        <%= for user <- @users do %>
                          <div class="flex items-center justify-between py-3">
                            <div class="flex items-center">
                              <.link navigate={~p"/profile/#{user.id}"} class="text-sm text-zinc-600 hover:text-zinc-900">
                                <%= user.email %>
                              </.link>
                              <%= if user.is_admin do %>
                                <span class="ml-2 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
                                  Admin
                                </span>
                              <% end %>
                            </div>
                            <span class="text-xs text-zinc-500">
                              Joined <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %>
                            </span>
                          </div>
                        <% end %>
                      </div>
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
          <% else %>
            <div class="mt-10 flex items-center justify-center gap-x-6">
              <.link
                navigate="/users/register"
                class="rounded-lg bg-zinc-900 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-zinc-600"
              >
                Register
              </.link>
              <.link
                navigate="/users/log_in"
                class="text-sm font-semibold leading-6 text-zinc-900"
              >
                Log in <span aria-hidden="true">→</span>
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
