defmodule SchedshareWeb.Live.Components.AdminUsersComponent do
  use SchedshareWeb, :live_component
  alias SchedshareWeb.DatetimeHelper

  def render(assigns) do
    ~H"""
    <div class="mt-8">
      <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">Users</h3>
      <div class="mt-4 divide-y divide-surface-light dark:divide-surface-dark">
        <%= for %{user: user, has_credentials: has_credentials, last_sync: last_sync} <- @users do %>
          <div class="flex items-center justify-between py-3">
            <div class="flex items-center gap-2">
              <.link navigate={~p"/profile/#{user.id}"} class="text-sm text-text-secondary-light dark:text-text-secondary-dark hover:text-interactive-secondary-light dark:hover:text-interactive-secondary-dark">
                <%= user.email %>
              </.link>
              <%= if user.is_admin do %>
                <span class="rounded-full bg-status-successBg-light dark:bg-status-successBg-dark px-2 py-0.5 text-xs font-medium text-status-success-light dark:text-status-success-dark">
                  Admin
                </span>
              <% end %>
              <%= if has_credentials do %>
                <span class="rounded-full bg-surface-light dark:bg-surface-dark px-2 py-0.5 text-xs font-medium text-text-primary-light dark:text-text-primary-dark">
                  Has API Key
                </span>
              <% else %>
                <span class="rounded-full bg-surface-light dark:bg-surface-dark px-2 py-0.5 text-xs font-medium text-text-primary-light dark:text-text-primary-dark">
                  No API Key
                </span>
              <% end %>
            </div>
            <div class="flex items-center gap-4 text-xs text-text-secondary-light dark:text-text-secondary-dark">
              <span>
                <%= if last_sync do %>
                  Last sync: <%= DatetimeHelper.format_datetime(last_sync) %>
                <% else %>
                  Never synced
                <% end %>
              </span>
              <span>
                Joined <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %>
              </span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
