defmodule SchedshareWeb.UserLoginLive do
  use SchedshareWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <span class="text-text-primary-light dark:text-text-primary-dark">Log in to account</span>
        <:subtitle>
          <span class="text-text-secondary-light dark:text-text-secondary-dark">
            Don't have an account?
            <.link navigate={~p"/users/register"} class="font-semibold text-interactive-primary-light dark:text-interactive-primary-dark hover:text-interactive-primary-light/80 dark:hover:text-interactive-primary-dark/80">
              Sign up
            </.link>
            for an account now.
          </span>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full bg-interactive-light dark:bg-interactive-dark text-interactive-dark dark:text-interactive-light hover:bg-interactive-light/80 dark:hover:bg-interactive-dark/80">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
