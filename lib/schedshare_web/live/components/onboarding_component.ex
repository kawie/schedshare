defmodule SchedshareWeb.Live.Components.OnboardingComponent do
  use SchedshareWeb, :live_component
  alias Schedshare.Scheduling
  alias Schedshare.Scheduling.HTTPClient
  alias Schedshare.Accounts

  def render(assigns) do
    ~H"""
    <div id={"onboarding-#{@id}"} class="mt-8">
      <%= if is_nil(@current_user.name) do %>
        <!-- Name prompt -->
        <div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
          <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">
              Nice to meet you!
            </h3>
            <p class="mt-2 text-sm text-text-secondary-light dark:text-text-secondary-dark">
              What would you like to be called?
            </p>
          </div>

          <.form
            for={@name_form}
            phx-submit="save_name"
            phx-target={@myself}
            class="space-y-4"
          >
            <div>
              <.input
                field={@name_form[:name]}
                type="text"
                label="First Name"
                placeholder="Enter your first name"
                required
              />
            </div>

            <div class="flex items-center justify-between pt-4">
              <.button
                type="submit"
                class="w-full"
                phx-disable-with="Saving..."
              >
                Continue
              </.button>
            </div>
          </.form>

          <%= if @name_error do %>
            <div class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
              <p class="text-sm text-red-600 dark:text-red-400">
                <%= @name_error %>
              </p>
            </div>
          <% end %>
        </div>
      <% else %>
        <!-- API credentials prompt -->
        <div class="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
          <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-text-primary-light dark:text-text-primary-dark">
              Connect to <%= @schedule_provider_name %>
            </h3>
            <p class="mt-2 text-sm text-text-secondary-light dark:text-text-secondary-dark">
              Enter your credentials to start syncing your schedule with friends
            </p>
          </div>

          <.form
            for={@form}
            phx-submit="save_credentials"
            phx-target={@myself}
            class="space-y-4"
          >
            <div>
              <.input
                field={@form[:username]}
                type="text"
                label="Username"
                placeholder="Enter your username"
                required
              />
            </div>

            <div>
              <.input
                field={@form[:plaintext_password]}
                type="password"
                label="Password"
                placeholder="Enter your password"
                required
              />
            </div>

            <div class="flex items-center justify-between pt-4">
              <.button
                type="submit"
                class="w-full"
                phx-disable-with="Connecting..."
              >
                Connect Account
              </.button>
            </div>
          </.form>

          <%= if @error do %>
            <div class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
              <p class="text-sm text-red-600 dark:text-red-400">
                <%= @error %>
              </p>
            </div>
          <% end %>

          <div class="mt-6 text-center">
            <p class="text-xs text-text-secondary-light dark:text-text-secondary-dark">
              Your credentials are encrypted and stored securely. We only use them to sync your schedule.
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

        def update(assigns, socket) do
    schedule_provider_name = Application.get_env(:schedshare, :schedule_provider_name, "Your Sports Provider")

    credential = %Scheduling.ApiCredential{}
    form = Scheduling.change_api_credential(credential, %{}) |> to_form()

    name_form = Accounts.change_user_profile(assigns.current_user, %{}) |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:name_form, name_form)
     |> assign(:error, nil)
     |> assign(:name_error, nil)
     |> assign(:schedule_provider_name, schedule_provider_name)}
  end

  def handle_event("save_name", %{"user" => params}, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, params) do
      {:ok, updated_user} ->
        send(self(), {:name_saved, updated_user})
        {:noreply, socket}

      {:error, changeset} ->
        name_form = to_form(changeset)
        name_error = "Please enter a valid name (2-50 characters)."
        {:noreply, assign(socket, name_form: name_form, name_error: name_error)}
    end
  end

  def handle_event("save_credentials", %{"api_credential" => credential_params}, socket) do
    # Encrypt the plaintext password for API authentication
    encrypted_password = Schedshare.Crypto.encrypt(credential_params["plaintext_password"])

    case HTTPClient.authenticate(credential_params["username"], encrypted_password) do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => %{"access_token" => access_token, "refresh_token" => refresh_token, "expires_in" => expires_in}}}} ->
        # Calculate token expiry time
        expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)

        # Add tokens and expiry to params
        credential_params = Map.merge(credential_params, %{
          "access_token" => access_token,
          "refresh_token" => refresh_token,
          "token_expires_at" => expires_at,
          "connection_status" => "connected",
          "connection_error" => nil
        })

        case Scheduling.create_or_update_api_credential(socket.assigns.current_user.id, credential_params) do
          {:ok, _credential} ->
            send(self(), {:credentials_saved, socket.assigns.current_user.id})
            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            form = to_form(changeset)
            error = "Failed to save credentials. Please check your input and try again."
            {:noreply, assign(socket, form: form, error: error)}
        end

      {:ok, %Tesla.Env{body: %{"error_description" => error}}} ->
        {:noreply, assign(socket, error: "Failed to connect: #{error}")}

      {:error, _error} ->
        {:noreply, assign(socket, error: "Failed to connect to API. Please check your credentials and try again.")}
    end
  end
end
