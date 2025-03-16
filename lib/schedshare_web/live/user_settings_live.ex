defmodule SchedshareWeb.UserSettingsLive do
  use SchedshareWeb, :live_view

  alias Schedshare.Accounts

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

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
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
