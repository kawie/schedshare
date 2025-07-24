defmodule SchedshareWeb.Router do
  use SchedshareWeb, :router

  import SchedshareWeb.UserAuth

  # ## Pipelines
  # Define the common pipelines used across different scopes

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SchedshareWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug SchedshareWeb.Plugs.EnsureAdmin
  end

  # ## Public Routes
  # Routes accessible to all users, including unauthenticated ones
  scope "/", SchedshareWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{SchedshareWeb.UserAuth, :mount_current_user}] do
      live "/", IndexLive, :index
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
      get "/profile/:user_id/calendar.ics", CalendarController, :calendar_ics
      get "/bookings/:id", BookingController, :show
    end

    delete "/users/log_out", UserSessionController, :delete
  end

  # ## Authentication Routes
  # Routes for user authentication and registration
  scope "/", SchedshareWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SchedshareWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  # ## Protected Routes
  # Routes that require authentication
  scope "/", SchedshareWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated_user,
      on_mount: [{SchedshareWeb.UserAuth, :mount_current_user},
                 {SchedshareWeb.UserAuth, :ensure_authenticated}] do
      live "/profile", ProfileLive, :index
      live "/profile/:id", ProfileLive, :show
      live "/calendar", CalendarLive, :index
    end

    live_session :require_authenticated_user,
      on_mount: [{SchedshareWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  # ## Development Routes
  # Routes only available in development environment
  if Application.compile_env(:schedshare, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:browser, :admin]
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # ## Admin Routes
  # Routes accessible only to admin users
  import Phoenix.LiveDashboard.Router
  use ErrorTracker.Web, :router

  scope "/admin" do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard", metrics: SchedshareWeb.Telemetry
    # ErrorTracker provides a dashboard for monitoring and debugging application errors
    # Accessible at /admin/errors
    error_tracker_dashboard "/errors"
  end
end
