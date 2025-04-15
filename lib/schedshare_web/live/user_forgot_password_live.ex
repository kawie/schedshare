defmodule SchedshareWeb.UserForgotPasswordLive do
  use SchedshareWeb, :live_view

  alias Schedshare.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <span class="text-text-primary-light dark:text-text-primary-dark">
          Forgot your password?
        </span>
        <:subtitle>
          <span class="text-text-secondary-light dark:text-text-secondary-dark">
            We'll send a password reset link to your inbox
          </span>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full bg-interactive-light dark:bg-interactive-dark text-interactive-dark dark:text-interactive-light hover:bg-interactive-light/80 dark:hover:bg-interactive-dark/80">
            Send password reset instructions
          </.button>
        </:actions>
      </.simple_form>
      <p class="text-center text-sm mt-4 text-text-secondary-light dark:text-text-secondary-dark">
        <.link href={~p"/users/register"} class="text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80">Register</.link>
        | <.link href={~p"/users/log_in"} class="text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80">Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
