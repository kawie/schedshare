defmodule SchedshareWeb.UserConfirmationInstructionsLive do
  use SchedshareWeb, :live_view

  alias Schedshare.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <span class="text-text-primary-light dark:text-text-primary-dark">
          No confirmation instructions received?
        </span>
        <:subtitle>
          <span class="text-text-secondary-light dark:text-text-secondary-dark">
            We'll send a new confirmation link to your inbox
          </span>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full bg-interactive-light dark:bg-interactive-dark text-interactive-dark dark:text-interactive-light hover:bg-interactive-light/80 dark:hover:bg-interactive-dark/80">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4 text-text-secondary-light dark:text-text-secondary-dark">
        <.link href={~p"/users/register"} class="text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80">Register</.link>
        | <.link href={~p"/users/log_in"} class="text-interactive-light dark:text-interactive-dark hover:text-interactive-light/80 dark:hover:text-interactive-dark/80">Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
