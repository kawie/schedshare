defmodule SchedshareWeb.Live.Components.PendingRequestsComponent do
  use SchedshareWeb, :live_component

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
                    phx-value-id={request.id}
                    class="rounded-md bg-status-successBg-light dark:bg-status-successBg-dark px-2.5 py-1.5 text-sm font-semibold text-status-success-light dark:text-status-success-dark shadow-sm hover:bg-status-successBg-light/80 dark:hover:bg-status-successBg-dark/80"
                  >
                    Accept
                  </button>
                  <button
                    phx-click="reject_request"
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
end
