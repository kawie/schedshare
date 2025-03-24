defmodule SchedshareWeb.Live.Components.WelcomeSectionComponent do
  use SchedshareWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"welcome-section-#{@id}"}>
      <h1 class="text-4xl font-bold tracking-tight text-zinc-900 sm:text-6xl">
        SchedShare
      </h1>
      <p class="mt-6 text-lg leading-8 text-zinc-600">
        Share and sync your sports class schedules with friends
      </p>
      <div class="mt-10 flex items-center justify-center gap-x-6">
        <.link
          navigate="/users/register"
          class="rounded-lg bg-zinc-900 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-zinc-600"
        >
          Register
        </.link>
        <.link
          navigate="/users/log_in"
          class="text-sm font-semibold leading-6 text-zinc-900"
        >
          Log in <span aria-hidden="true">→</span>
        </.link>
      </div>
      <div class="mt-10">
        <p>Questions? <a href="mailto:post@kai.gs" class="text-emerald-600 hover:text-emerald-500">post@kai.gs</a></p>
      </div>
    </div>
    """
  end
end
