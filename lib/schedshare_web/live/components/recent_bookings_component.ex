defmodule SchedshareWeb.Live.Components.RecentBookingsComponent do
  use SchedshareWeb, :live_component
  alias SchedshareWeb.DatetimeHelper

  def render(assigns) do
    ~H"""
    <div id={"recent-bookings-#{@id}"}>
      <%= if length(@recent_bookings) > 0 do %>
        <div class="mt-8 border-t border-zinc-200 pt-8">
          <h3 class="text-lg font-semibold text-zinc-900">Recent Bookings from People You Follow</h3>
          <div class="mt-4 divide-y divide-zinc-200">
            <%= for booking <- @recent_bookings do %>
              <div class="py-4">
                <div class="flex items-center gap-3 mb-2">
                  <.link navigate={~p"/profile/#{booking.schedule.user.id}"} class="flex items-center gap-3 text-zinc-900 hover:text-zinc-600">
                    <%= if booking.schedule.user.profile_picture do %>
                      <img src={booking.schedule.user.profile_picture} alt={booking.schedule.user.name || booking.schedule.user.email} class="h-8 w-8 rounded-full" />
                    <% else %>
                      <div class="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                        <.icon name="hero-user" class="w-4 h-4 text-gray-500" />
                      </div>
                    <% end %>
                    <span class="text-sm font-medium"><%= booking.schedule.user.name || booking.schedule.user.email %></span>
                  </.link>
                  <span class="text-sm text-zinc-500">booked</span>
                </div>
                <div class="pl-11">
                  <h4 class="text-base font-medium text-zinc-900">
                    <a href={"#{System.get_env("EXTERNAL_DOMAIN")}/activities?class=#{booking.course_external_id}"} target="_blank" class="hover:text-emerald-600 inline-flex items-center gap-1">
                      <%= booking.course_title %>
                      <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                    </a>
                  </h4>
                  <div class="mt-1 text-sm text-zinc-500">
                    <%= DatetimeHelper.format_weekday_date(booking.start_datetime_utc) %> at <%= DatetimeHelper.format_time(booking.start_datetime_utc) %>
                  </div>
                  <div class="text-sm text-zinc-500">
                    <%= booking.venue_name %>
                  </div>
                  <div class="mt-1 text-xs text-zinc-400">
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
