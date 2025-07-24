defmodule SchedshareWeb.Live.Components.OnboardingComponentTest do
  use SchedshareWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias SchedshareWeb.Live.Components.OnboardingComponent

  setup do
    user = Schedshare.AccountsFixtures.user_fixture()
    %{user: user}
  end

    test "renders name prompt for user without name", %{user: user} do
    # Ensure user has no name
    user_without_name = %{user | name: nil}
    assigns = %{current_user: user_without_name, id: "test"}

    html = render_component(OnboardingComponent, assigns)

    assert html =~ "Nice to meet you!"
    assert html =~ "What would you like to be called?"
    assert html =~ "First Name"
    assert html =~ "Continue"
  end

    test "renders credentials form for user with name but no credentials", %{user: user} do
    # Give user a name
    user_with_name = %{user | name: "John"}
    assigns = %{current_user: user_with_name, id: "test"}

    html = render_component(OnboardingComponent, assigns)

    assert html =~ "Connect to Test Sports Provider"
    assert html =~ "Enter your credentials to start syncing your schedule with friends"
    assert html =~ "Username"
    assert html =~ "Password"
    assert html =~ "Connect Account"
    assert html =~ "Your credentials are encrypted and stored securely"
  end

    test "shows custom schedule provider name from config", %{user: user} do
    # Temporarily set a custom provider name
    original_name = Application.get_env(:schedshare, :schedule_provider_name)
    Application.put_env(:schedshare, :schedule_provider_name, "Custom Sports Provider")

    # Give user a name so it shows the credentials form
    user_with_name = %{user | name: "John"}
    assigns = %{current_user: user_with_name, id: "test"}
    html = render_component(OnboardingComponent, assigns)

    assert html =~ "Connect to Custom Sports Provider"

    # Restore original config
    Application.put_env(:schedshare, :schedule_provider_name, original_name)
  end
end
