defmodule Schedshare.Scheduling.Sync do
  @moduledoc """
  Handles syncing schedules with the sports platform API.
  This module can be used both for manual syncing from the UI and automated syncing via a scheduler.
  """

  require Logger
  alias Schedshare.Scheduling.{HTTPClient, ApiCredential}

  @doc """
  Syncs a user's schedule with the sports platform.
  Returns {:ok, credential} on success or {:error, reason} on failure.
  """
  def sync_user_schedule(user_id) do
    case Schedshare.Scheduling.get_user_api_credential(user_id) do
      nil ->
        {:error, "No API credentials found"}

      credential ->
        sync_with_credential(credential)
    end
  end

  @doc """
  Syncs a schedule using the provided API credential.
  Returns {:ok, credential} on success or {:error, reason} on failure.
  """
  def sync_with_credential(%ApiCredential{} = credential) do
    case HTTPClient.fetch_schedule(credential.access_token) do
      {:ok, %Tesla.Env{status: 200, body: %{"bookings" => bookings}}} ->
        case Schedshare.Scheduling.sync_bookings(credential.user_id, bookings) do
          {:ok, _} ->
            # Update last sync time
            Schedshare.Scheduling.update_api_credential(credential, %{
              last_sync_at: DateTime.utc_now(),
              connection_status: "connected",
              connection_error: nil
            })

          {:error, error} ->
            {:error, "Failed to sync bookings: #{error}"}
        end

      {:ok, %Tesla.Env{status: 401, body: %{"error" => "invalid_token"}}} ->
        # Token expired, try to refresh it
        case HTTPClient.refresh_token(credential.refresh_token) do
          {:ok, %Tesla.Env{status: 200, body: %{"access_token" => access_token, "refresh_token" => refresh_token, "expires_in" => expires_in}}} ->
            expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)

            # Update credential with new tokens
            case Schedshare.Scheduling.update_api_credential(credential, %{
              access_token: access_token,
              refresh_token: refresh_token,
              token_expires_at: expires_at
            }) do
              {:ok, updated_credential} ->
                # Retry sync with new token
                sync_with_credential(updated_credential)

              {:error, error} ->
                {:error, "Failed to update credential with new tokens: #{error}"}
            end

          {:ok, %Tesla.Env{status: status, body: body}} ->
            error = "Failed to refresh token: #{status} - #{inspect(body)}"
            Schedshare.Scheduling.update_api_credential(credential, %{
              connection_status: "error",
              connection_error: error
            })
            {:error, error}

          {:error, error} ->
            Schedshare.Scheduling.update_api_credential(credential, %{
              connection_status: "error",
              connection_error: error
            })
            {:error, "Failed to refresh token: #{error}"}
        end

      {:ok, %Tesla.Env{status: status, body: body}} ->
        error = "API returned status #{status}: #{inspect(body)}"
        Schedshare.Scheduling.update_api_credential(credential, %{
          connection_status: "error",
          connection_error: error
        })
        {:error, error}

      {:error, error} ->
        Schedshare.Scheduling.update_api_credential(credential, %{
          connection_status: "error",
          connection_error: error
        })
        {:error, "Failed to fetch schedule: #{error}"}
    end
  end
end
