defmodule SchedshareWeb.Live.Components.StyledLinkComponent do
  use SchedshareWeb, :live_component

  def render(assigns) do
    ~H"""
    <.link
      {@rest}
      class="text-sm font-semibold leading-6 text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80"
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
