defmodule SchedshareWeb.Live.Components.PeopleYouMightKnowComponent do
  use SchedshareWeb, :live_component
  alias Schedshare.Accounts

  def render(assigns) do
    ~H"""
    <div id={"people-you-might-know-#{@id}"} class="mt-8">
      <div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">
            People you might know
          </h3>
          <p class="mt-2 text-sm text-text-secondary-light dark:text-text-secondary-dark">
            Connect with other users to see their schedules
          </p>
        </div>

        <div class="space-y-4">
          <%= for user <- @suggested_users do %>
            <div class="flex items-center justify-between p-4 border border-border-light dark:border-border-dark rounded-lg">
              <.link
                navigate={~p"/profile/#{user.id}"}
                class="flex items-center space-x-3 hover:bg-surface-light/60 dark:hover:bg-surface-dark/60 rounded-lg px-1 py-1 transition-colors"
              >
                <%= if user.profile_picture do %>
                  <img src={user.profile_picture} alt="" class="h-10 w-10 rounded-full object-cover" />
                <% else %>
                  <div class="h-10 w-10 rounded-full bg-surface-light dark:bg-surface-dark flex items-center justify-center">
                    <.icon name="hero-user" class="w-5 h-5 text-text-secondary-light dark:text-text-secondary-dark" />
                  </div>
                <% end %>
                <div>
                  <p class="text-sm font-medium text-text-primary-light dark:text-text-primary-dark">
                    <%= user.name %>
                  </p>
                </div>
              </.link>

              <button
                type="button"
                phx-click="send_friend_request"
                phx-value-user-id={user.id}
                phx-target={@myself}
                class="px-3 py-1.5 text-sm font-medium text-interactive-primary-light dark:text-interactive-primary-dark bg-surface-light dark:bg-surface-dark border border-interactive-primary-light dark:border-interactive-primary-dark rounded-md hover:bg-interactive-primary-light hover:text-white dark:hover:bg-interactive-primary-dark dark:hover:text-white transition-colors"
              >
                Add Friend
              </button>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("send_friend_request", %{"user-id" => target_user_id}, socket) do
    case Accounts.send_friend_request(socket.assigns.current_user.id, target_user_id) do
      {:ok, _friendship} ->
        # Remove the user from suggested list
        updated_suggested_users = Enum.reject(socket.assigns.suggested_users, fn user ->
          user.id == String.to_integer(target_user_id)
        end)

        {:noreply,
         socket
         |> assign(:suggested_users, updated_suggested_users)
         |> put_flash(:info, "Friend request sent!")}

      {:error, :already_friends} ->
        {:noreply, put_flash(socket, :error, "You are already friends with this user.")}

      {:error, :request_already_sent} ->
        {:noreply, put_flash(socket, :error, "Friend request already sent.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to send friend request.")}
    end
  end


end
