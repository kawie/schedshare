defmodule SchedshareWeb.Live.Components.WelcomeSectionComponent do
  use SchedshareWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"welcome-section-#{@id}"}>
      <h1 class="text-4xl font-bold tracking-tight text-text-primary-light dark:text-text-primary-dark sm:text-6xl">
        SchedShare
      </h1>
      <p class="mt-6 text-lg leading-8 text-text-secondary-light dark:text-text-secondary-dark">
        Share and sync your sports class schedules with friends
      </p>
      <div class="mt-10 flex items-center justify-center gap-x-6">
        <.link
          navigate="/users/register"
          class="rounded-lg bg-interactive-primary-light dark:bg-interactive-primary-dark px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-interactive-primary-light/80 dark:hover:bg-interactive-primary-dark/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-interactive-primary-light/50 dark:focus-visible:outline-interactive-primary-dark/50"
        >
          Register
        </.link>
        <.link
          navigate="/users/log_in"
          class="text-sm font-semibold leading-6 text-interactive-secondary-light dark:text-interactive-secondary-dark hover:text-interactive-secondary-light/80 dark:hover:text-interactive-secondary-dark/80"
        >
          Log in <span aria-hidden="true">→</span>
        </.link>
      </div>
      <div class="mt-10">
        <p class="text-text-secondary-light dark:text-text-secondary-dark">
          Questions?
          <.link
            href="mailto:post@kai.gs"
            class="text-interactive-primary-light dark:text-interactive-primary-dark hover:text-interactive-primary-light/80 dark:hover:text-interactive-primary-dark/80"
          >
            post@kai.gs
          </.link>
        </p>
      </div>
    </div>
    """
  end
end
