defmodule SchedshareWeb.Live.Components.RecentBookingsComponent do
  use SchedshareWeb, :live_component
  alias SchedshareWeb.DatetimeHelper
  alias Schedshare.Scheduling
  alias Phoenix.PubSub

  def mount(socket) do
    if connected?(socket) and socket.assigns[:current_user] do
      # Subscribe to booking updates for the current user
      PubSub.subscribe(Schedshare.PubSub, "user_bookings:#{socket.assigns.current_user.id}")
    end
    {:ok, socket}
  end

  def handle_info({:booking_created, booking}, socket) do
    # Add the new booking to the list if it's not already there
    if Enum.any?(socket.assigns.recent_bookings, &(&1.id == booking.id)) do
      {:noreply, socket}
    else
      {:noreply, assign(socket, recent_bookings: [booking | socket.assigns.recent_bookings])}
    end
  end

  def handle_info({:booking_updated, booking}, socket) do
    # Update the booking in the list if it exists
    updated_bookings = Enum.map(socket.assigns.recent_bookings, fn existing_booking ->
      if existing_booking.id == booking.id do
        booking
      else
        existing_booking
      end
    end)
    {:noreply, assign(socket, recent_bookings: updated_bookings)}
  end

  def handle_info({:booking_deleted, booking_id}, socket) do
    # Remove the booking from the list
    updated_bookings = Enum.reject(socket.assigns.recent_bookings, &(&1.id == booking_id))
    {:noreply, assign(socket, recent_bookings: updated_bookings)}
  end

  def render(assigns) do
    ~H"""
    <div id={"recent-bookings-#{@id}"}>
      <%= if length(@recent_bookings) > 0 do %>
        <div class="mt-8 border-t border-border-light dark:border-border-dark pt-8">
          <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">Recent Bookings from Friends</h3>
          <div class="mt-4 divide-y divide-border-light dark:divide-border-dark">
            <%= for booking <- @recent_bookings do %>
              <div class="py-4">
                <div class="flex items-center gap-3 mb-2">
                  <.link navigate={~p"/profile/#{booking.schedule.user.id}"} class="flex items-center gap-3 text-text-primary-light dark:text-text-primary-dark hover:text-interactive-secondary-light dark:hover:text-interactive-secondary-dark">
                    <%= if booking.schedule.user.profile_picture do %>
                      <img src={booking.schedule.user.profile_picture} alt={booking.schedule.user.name || booking.schedule.user.email} class="h-8 w-8 rounded-full" />
                    <% else %>
                      <div class="h-8 w-8 rounded-full bg-surface-light dark:bg-surface-dark flex items-center justify-center">
                        <.icon name="hero-user" class="w-4 h-4 text-text-secondary-light dark:text-text-secondary-dark" />
                      </div>
                    <% end %>
                    <span class="text-sm font-medium"><%= booking.schedule.user.name || booking.schedule.user.email %></span>
                  </.link>
                  <span class="text-sm text-text-secondary-light dark:text-text-secondary-dark">booked</span>
                </div>
                <div class="pl-11">
                  <h4 class="text-base font-medium text-text-primary-light dark:text-text-primary-dark">
                    <a href={"#{System.get_env("EXTERNAL_DOMAIN")}/activities?class=#{booking.course_external_id}"} target="_blank" class="hover:text-interactive-primary-light dark:hover:text-interactive-primary-dark inline-flex items-center gap-1">
                      <%= booking.course_title %>
                      <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                    </a>
                  </h4>
                  <div class="mt-1 text-sm text-text-secondary-light dark:text-text-secondary-dark">
                    <%= DatetimeHelper.format_weekday_date(booking.start_datetime_utc) %> at <%= DatetimeHelper.format_time(booking.start_datetime_utc) %>
                  </div>
                  <div class="text-sm text-text-secondary-light dark:text-text-secondary-dark">
                    <%= booking.venue_name %>
                  </div>
                  <div class="mt-1 text-xs text-text-tertiary-light dark:text-text-tertiary-dark">
                    Booked <%= DatetimeHelper.format_relative_time(booking.inserted_at) %>
                  </div>
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
