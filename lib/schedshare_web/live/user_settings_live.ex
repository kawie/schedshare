defmodule SchedshareWeb.UserSettingsLive do
  use SchedshareWeb, :live_view

  alias Schedshare.Accounts
  alias Schedshare.Scheduling
  alias Schedshare.Scheduling.{ApiCredential, HTTPClient}

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account settings and profile</:subtitle>
    </.header>

    <div class="space-y-12 divide-y max-w-2xl mx-auto">
      <div class="mt-10">
        <.header>
          Profile Settings
          <:subtitle>Update your name and profile picture</:subtitle>
        </.header>

        <div class="mt-6">
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-submit="update_profile"
            phx-change="validate_profile"
          >
            <.input field={@profile_form[:name]} type="text" label="Name" autocomplete="off" />
            <div phx-drop-target={@uploads.profile_picture.ref}>
              <.live_file_input upload={@uploads.profile_picture} class="hidden" />
              <div class="mt-2 flex items-center gap-x-3">
                <%= if @current_user.profile_picture do %>
                  <img src={@current_user.profile_picture} alt="" class="h-12 w-12 rounded-full" />
                <% else %>
                  <div class="h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center">
                    <.icon name="hero-user" class="w-6 h-6 text-gray-300" />
                  </div>
                <% end %>
                <button type="button" phx-click={JS.dispatch("click", to: "##{@uploads.profile_picture.ref}")} class="rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                  Change
                </button>
              </div>

              <%= for entry <- @uploads.profile_picture.entries do %>
                <div class="mt-2">
                  <div class="flex items-center gap-x-3">
                    <.live_img_preview entry={entry} class="h-12 w-12 rounded-full object-cover" />
                    <div class="flex items-center gap-x-2">
                      <div class="text-sm font-semibold text-gray-900"><%= entry.client_name %></div>
                      <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="rounded-full p-1 text-gray-500 hover:bg-gray-100">
                        <.icon name="hero-x-mark" class="w-5 h-5" />
                      </button>
                    </div>
                  </div>

                  <div :for={err <- upload_errors(@uploads.profile_picture, entry)} class="mt-2 text-sm text-red-600">
                    <%= Phoenix.Naming.humanize(err) %>
                  </div>
                </div>
              <% end %>

              <div :for={err <- upload_errors(@uploads.profile_picture)} class="mt-2 text-sm text-red-600">
                <%= Phoenix.Naming.humanize(err) %>
              </div>
            </div>

            <:actions>
              <.button phx-disable-with="Saving...">Save Profile</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>

      <div class="mt-10">
        <.header>
          API Credentials
          <:subtitle>Connect your account to schedule providers</:subtitle>
        </.header>

        <div class="mt-6">
          <.form :let={f} for={@api_credential_changeset} phx-submit="save_credentials" class="space-y-4">
            <div>
              <.input field={f[:username]} type="text" label="Username" />
            </div>
            <div>
              <.input field={f[:password]} type="password" label="Password" />
            </div>
            <div class="flex items-center gap-4">
              <.button type="submit">Save Credentials</.button>
              <.button type="button" phx-click="test_connection" disabled={!@has_credentials}>
                Test Connection
              </.button>
              <.button type="button" phx-click="sync_schedule" disabled={!@has_credentials}>
                <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Sync Schedule
              </.button>
            </div>
          </.form>

          <%= if @api_credential do %>
            <div class="mt-4">
              <div class="flex items-center gap-2">
                <span class={[
                  "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium",
                  @api_credential.connection_status == "connected" && "bg-emerald-100 text-emerald-800",
                  @api_credential.connection_status == "error" && "bg-red-100 text-red-800",
                  @api_credential.connection_status == "disconnected" && "bg-yellow-100 text-yellow-800"
                ]}>
                  <%= @api_credential.connection_status %>
                </span>
                <%= if @api_credential.last_sync_at do %>
                  <span class="text-sm text-zinc-500">
                    Last synced <%= Calendar.strftime(@api_credential.last_sync_at, "%B %d, %Y at %H:%M") %>
                  </span>
                <% end %>
              </div>
              <%= if @api_credential.connection_error do %>
                <p class="mt-2 text-sm text-red-600"><%= @api_credential.connection_error %></p>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-10">
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required autocomplete="email" />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
            autocomplete="current-password"
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>

      <div class="mt-10">
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            required
            autocomplete="new-password"
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
            autocomplete="current-password"
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user)

    # Load API credentials
    api_credential = Scheduling.get_user_api_credential(user.id)
    api_credential_changeset = Scheduling.change_api_credential(api_credential || %ApiCredential{})
    has_credentials = not is_nil(api_credential)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:api_credential, api_credential)
      |> assign(:api_credential_changeset, api_credential_changeset)
      |> assign(:has_credentials, has_credentials)
      |> assign(:trigger_submit, false)
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  def handle_event("save_credentials", %{"api_credential" => credential_params}, socket) do
    case HTTPClient.authenticate(credential_params["username"], credential_params["password"]) do
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
          {:ok, credential} ->
            {:noreply,
             socket
             |> assign(
               api_credential: credential,
               api_credential_changeset: Scheduling.change_api_credential(credential),
               has_credentials: true
             )
             |> put_flash(:info, "API credentials saved successfully")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> assign(api_credential_changeset: changeset)
             |> put_flash(:error, "Failed to save API credentials")}
        end

      {:ok, %Tesla.Env{body: %{"error_description" => error}}} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to connect: #{error}")
         |> assign(api_credential_changeset: socket.assigns.api_credential_changeset)}

      {:error, _error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to connect to API")}
    end
  end

  def handle_event("test_connection", _, socket) do
    case HTTPClient.get_customer_info(socket.assigns.api_credential.access_token) do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => _customer_data}}} ->
        {:noreply,
         socket
         |> assign(
           api_credential: %{socket.assigns.api_credential | connection_status: "connected", connection_error: nil}
         )
         |> put_flash(:info, "Connection successful!")}

      {:ok, %Tesla.Env{body: %{"error_description" => error}}} ->
        {:noreply,
         socket
         |> assign(
           api_credential: %{socket.assigns.api_credential | connection_status: "error", connection_error: error}
         )
         |> put_flash(:error, "Connection failed: #{error}")}

      {:ok, %Tesla.Env{status: status}} ->
        error_message = "Connection failed with status #{status}"
        {:noreply,
         socket
         |> assign(
           api_credential: %{socket.assigns.api_credential | connection_status: "error", connection_error: error_message}
         )
         |> put_flash(:error, error_message)}

      {:error, _error} ->
        error_message = "Failed to connect to API"
        {:noreply,
         socket
         |> assign(
           api_credential: %{socket.assigns.api_credential | connection_status: "error", connection_error: error_message}
         )
         |> put_flash(:error, error_message)}
    end
  end

  def handle_event("sync_schedule", _, socket) do
    case Schedshare.Scheduling.Sync.sync_user_schedule(socket.assigns.current_user.id) do
      {:ok, updated_credential} ->
        {:noreply,
         socket
         |> assign(api_credential: updated_credential)
         |> put_flash(:info, "Schedule synced successfully!")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to sync schedule: #{error}")}
    end
  end

  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    profile_form =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_picture, ref)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    profile_params =
      case uploaded_entries(socket, :profile_picture) do
        {[entry], []} ->
          # Get the binary data of the uploaded file
          consumed_entries = consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, _entry ->
            {:ok, File.read!(path)}
          end)

          # Add the uploaded file data to the params
          Map.put(user_params, "profile_picture", %{
            content_type: entry.client_type,
            path: List.first(consumed_entries)
          })
        {[], []} ->
          user_params
      end

    case Accounts.update_user_profile(user, profile_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Profile updated successfully.")
         |> push_navigate(to: ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
