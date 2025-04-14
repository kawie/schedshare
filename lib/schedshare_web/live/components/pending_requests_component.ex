defmodule SchedshareWeb.Live.Components.PendingRequestsComponent do
  use SchedshareWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"pending-requests-#{@id}"}>
      <%= if length(@pending_requests) > 0 do %>
        <div class="mt-4">
          <h3 class="text-lg font-semibold text-zinc-900">Pending Friend Requests</h3>
          <div class="mt-2 divide-y divide-zinc-200">
            <%= for request <- @pending_requests do %>
              <div class="flex items-center justify-between py-3">
                <div class="flex items-center gap-3">
                  <%= if request.requested_by.profile_picture do %>
                    <img src={request.requested_by.profile_picture} alt={request.requested_by.name || request.requested_by.email} class="h-8 w-8 rounded-full" />
                  <% else %>
                    <div class="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                      <.icon name="hero-user" class="w-4 h-4 text-gray-500" />
                    </div>
                  <% end %>
                  <div>
                    <div class="text-sm font-medium text-zinc-900">
                      <%= request.requested_by.name || request.requested_by.email %>
                    </div>
                    <%= if request.requested_by.name do %>
                      <div class="text-xs text-zinc-500">
                        <%= request.requested_by.email %>
                      </div>
                    <% end %>
                  </div>
                </div>
                <div class="flex gap-2">
                  <button
                    phx-click="accept_request"
                    phx-value-id={request.id}
                    class="rounded-md bg-emerald-600 px-2.5 py-1.5 text-sm font-semibold text-white shadow-sm hover:bg-emerald-500"
                  >
                    Accept
                  </button>
                  <button
                    phx-click="reject_request"
                    phx-value-id={request.id}
                    class="rounded-md bg-zinc-600 px-2.5 py-1.5 text-sm font-semibold text-white shadow-sm hover:bg-zinc-500"
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
