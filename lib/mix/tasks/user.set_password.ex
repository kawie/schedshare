defmodule Mix.Tasks.User.SetPassword do
  @moduledoc """
  Sets or resets a user's password.

  ## Usage

      mix user.set_password EMAIL NEW_PASSWORD

  Example:
      mix user.set_password post@kai.gs my-new-password

  This task will:
  1. Look up the user by email
  2. Reset their password to the provided value
  3. Print the result of the operation
  """

  use Mix.Task
  alias Schedshare.Accounts

  @shortdoc "Sets a user's password"
  def run([email, password]) do
    Mix.Task.run("app.start")

    case Accounts.get_user_by_email(email) do
      nil ->
        Mix.shell().error("❌ No user found with email: #{email}")

      user ->
        case Accounts.reset_user_password(user, %{
          password: password,
          password_confirmation: password
        }) do
          {:ok, _updated_user} ->
            Mix.shell().info("✅ Successfully updated password for #{email}")

          {:error, changeset} ->
            Mix.shell().error("❌ Failed to update password:")
            Enum.each(changeset.errors, fn {field, {message, _}} ->
              Mix.shell().error("   #{field}: #{message}")
            end)
        end
    end
  end

  def run(_) do
    Mix.shell().error("❌ Expected exactly 2 arguments: EMAIL and NEW_PASSWORD")
    Mix.shell().info("\nUsage:\n    mix user.set_password EMAIL NEW_PASSWORD")
  end
end
