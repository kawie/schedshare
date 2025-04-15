defmodule SchedshareWeb.Live.Components.RecentBookingsComponent do
  use SchedshareWeb, :live_component
  alias SchedshareWeb.DatetimeHelper

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
