defmodule SchedshareWeb.Components.MenuItems do
  use SchedshareWeb, :html

  def menu_items(assigns) do
    ~H"""
    <%= if @current_user do %>
      <.link
        href={~p"/profile"}
        class={@class}
      >
        My Profile (<%= @current_user.email %>)
      </.link>

      <.link
        href={~p"/calendar"}
        class={@class}
      >
        Calendar
      </.link>

      <.link
        href={~p"/users/settings"}
        class={@class}
      >
        Settings
      </.link>
      <.link
        href={~p"/users/log_out"}
        method="delete"
        class={@class}
      >
        Log out
      </.link>
    <% else %>
      <.link
        href={~p"/users/register"}
        class={@class}
      >
        Register
      </.link>
      <.link
        href={~p"/users/log_in"}
        class={@class}
      >
        Log in
      </.link>
    <% end %>
    """
  end
end
