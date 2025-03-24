defmodule SchedshareWeb.Live.Components.AdminUsersComponent do
  use SchedshareWeb, :live_component
  alias SchedshareWeb.DatetimeHelper

  def render(assigns) do
    ~H"""
    <div class="mt-8">
      <h3 class="text-lg font-semibold text-zinc-900">Users</h3>
      <div class="mt-4 divide-y divide-zinc-200">
        <%= for %{user: user, has_credentials: has_credentials, last_sync: last_sync} <- @users do %>
          <div class="flex items-center justify-between py-3">
            <div class="flex items-center gap-2">
              <.link navigate={~p"/profile/#{user.id}"} class="text-sm text-zinc-600 hover:text-zinc-900">
                <%= user.email %>
              </.link>
              <%= if user.is_admin do %>
                <span class="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
                  Admin
                </span>
              <% end %>
              <%= if has_credentials do %>
                <span class="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-800">
                  Has API Key
                </span>
              <% else %>
                <span class="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-800">
                  No API Key
                </span>
              <% end %>
            </div>
            <div class="flex items-center gap-4 text-xs text-zinc-500">
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
