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
      {:ok, %Tesla.Env{status: 200} = response} ->
        Logger.debug("Got 200 response from API: #{inspect(response.body)}")
        case response.body do
          %{"data" => bookings} when is_list(bookings) ->
            # Transform bookings to match our expected format
            formatted_bookings = Enum.map(bookings, fn booking ->
              course = booking["course"]
              %{
                "id" => booking["id"],
                "status" => booking["status"],
                "title" => course["title"],
                "start_time" => course["startDateTimeUTC"],
                "end_time" => course["endDateTimeUTC"],
                "location" => course["venueName"],
                "teacher_name" => course["teacherName"],
                "course_external_id" => course["id"],
                "course_types" => course["types"],
                "is_online" => course["isOnline"] == 1
              }
            end)

            case Schedshare.Scheduling.sync_bookings(credential.user_id, formatted_bookings) do
              {:ok, _} ->
                # Update last sync time and clear any error state
                case Schedshare.Scheduling.update_api_credential(credential, %{
                  last_sync_at: DateTime.utc_now(),
                  connection_status: "connected",
                  connection_error: nil
                }) do
                  {:ok, updated_credential} -> {:ok, updated_credential}
                  {:error, error} -> {:error, "Failed to update credential after sync: #{error}"}
                end

              {:error, error} ->
                error_message = "Failed to sync bookings: #{error}"
                Schedshare.Scheduling.update_api_credential(credential, %{
                  connection_status: "error",
                  connection_error: error_message
                })
                {:error, error_message}
            end

          _ ->
            error_message = "Unexpected API response structure: #{inspect(response.body)}"
            Schedshare.Scheduling.update_api_credential(credential, %{
              connection_status: "error",
              connection_error: error_message
            })
            {:error, error_message}
        end

      {:ok, %Tesla.Env{status: 401}} ->
        # Token expired, try to refresh it
        case HTTPClient.refresh_token(credential.refresh_token) do
          {:ok, %Tesla.Env{status: 200, body: %{"data" => %{"access_token" => access_token, "refresh_token" => refresh_token, "expires_in" => expires_in}}}} ->
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
                error_message = "Failed to update credential with new tokens: #{error}"
                Schedshare.Scheduling.update_api_credential(credential, %{
                  connection_status: "error",
                  connection_error: error_message
                })
                {:error, error_message}
            end

          {:ok, %Tesla.Env{status: status, body: %{"error_description" => error}}} ->
            error_message = "Failed to refresh token: #{error}"
            Schedshare.Scheduling.update_api_credential(credential, %{
              connection_status: "error",
              connection_error: error_message
            })
            {:error, error_message}

          {:error, error} ->
            error_message = "Failed to refresh token: #{error}"
            Schedshare.Scheduling.update_api_credential(credential, %{
              connection_status: "error",
              connection_error: error_message
            })
            {:error, error_message}
        end

      {:ok, %Tesla.Env{status: status, body: %{"error_description" => error}}} ->
        error_message = "API returned error: #{error}"
        Schedshare.Scheduling.update_api_credential(credential, %{
          connection_status: "error",
          connection_error: error_message
        })
        {:error, error_message}

      {:ok, %Tesla.Env{status: status}} ->
        error_message = "API returned status #{status}"
        Schedshare.Scheduling.update_api_credential(credential, %{
          connection_status: "error",
          connection_error: error_message
        })
        {:error, error_message}

      {:error, error} ->
        error_message = "Failed to fetch schedule: #{error}"
        Schedshare.Scheduling.update_api_credential(credential, %{
          connection_status: "error",
          connection_error: error_message
        })
        {:error, error_message}
    end
  end
end
