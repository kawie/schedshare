defmodule SchedshareWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use SchedshareWeb, :controller` and
  `use SchedshareWeb, :live_view`.
  """
  use SchedshareWeb, :html

  import SchedshareWeb.Components.MenuItems, only: [menu_items: 1]

  embed_templates "layouts/*"

  def nav(assigns) do
    ~H"""
    <.nav_template current_user={@current_user} />
    """
  end

  defp nav_template(assigns) do
    ~H"""
    <header class="relative flex items-center justify-between py-3 px-4 sm:px-6 lg:px-8 border-b border-surface-light dark:border-surface-dark">
      <div class="flex items-center">
        <.link href={~p"/"} class="text-xl font-semibold text-text-primary-light dark:text-text-primary-dark">
          SchedShare
        </.link>
      </div>

      <!-- Mobile menu button -->
      <div class="flex sm:hidden">
        <button type="button" class="text-text-primary-light dark:text-text-primary-dark" data-menu-button>
          <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
          </svg>
        </button>
      </div>

      <!-- Mobile menu -->
      <div class="fixed inset-0 z-50 hidden transform bg-surface-light dark:bg-surface-dark transition-transform duration-300 ease-in-out translate-x-full sm:hidden" data-mobile-menu>
        <div class="flex h-full flex-col">
          <div class="flex justify-end p-4">
            <button type="button" class="text-text-primary-light dark:text-text-primary-dark" data-menu-close>
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <nav class="flex-1 space-y-1 px-4">
            <.menu_items current_user={@current_user} class="block text-[0.8125rem] leading-6 text-text-primary-light dark:text-text-primary-dark font-semibold hover:text-interactive-secondary-light dark:hover:text-interactive-secondary-dark py-2" />
          </nav>
        </div>
      </div>

      <!-- Desktop menu -->
      <ul class="hidden sm:flex items-center gap-4">
        <.menu_items current_user={@current_user} class="text-[0.8125rem] leading-6 text-text-primary-light dark:text-text-primary-dark font-semibold hover:text-interactive-secondary-light dark:hover:text-interactive-secondary-dark" />
      </ul>
    </header>
    """
  end
end
