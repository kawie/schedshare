defmodule Schedshare.Scheduling.HTTPClient do
  use Tesla
  require Logger

  plug Tesla.Middleware.BaseUrl, System.get_env("API_BASE_URL")
  plug Tesla.Middleware.Headers, [
    {"user-agent", "schedshare"}
  ]
  plug Tesla.Middleware.JSON

  @moduledoc """
  HTTP client for making requests to the sports schedule provider API.
  Handles authentication and schedule fetching with proper headers.

  In development and test environments, it uses a mock implementation that simulates
  the API responses. In production, it makes actual HTTP requests to the configured API endpoint.
  """

  @doc """
  Authenticates with the API using username and password.
  Returns {:ok, response} with access and refresh tokens on success.
  """
  def authenticate(username, password) do
    Logger.debug("Authenticating with username: #{username}")

    if mock?() do
      Logger.debug("Using mock authentication")
      mock_authenticate(username, password)
    else
      Logger.debug("Making real API authentication request")
      post("/api/v7/auth/token", %{
        grant_type: "password",
        username: username,
        password: password,
        client_id: System.get_env("API_CLIENT_ID"),
        client_secret: System.get_env("API_CLIENT_SECRET")
      })
    end
  end

  @doc """
  Refreshes the access token using the refresh token.
  Returns {:ok, response} with new access and refresh tokens on success.
  """
  def refresh_token(refresh_token) do
    Logger.debug("Refreshing access token")

    if mock?() do
      Logger.debug("Using mock token refresh")
      mock_refresh_token(refresh_token)
    else
      Logger.debug("Making real API token refresh request")
      post("/api/v7/auth/token", %{
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: System.get_env("API_CLIENT_ID"),
        client_secret: System.get_env("API_CLIENT_SECRET")
      })
    end
  end

  @doc """
  Fetches the user's schedule from the API.
  Returns {:ok, response} with the schedule data on success.
  """
  def fetch_schedule(access_token) do
    Logger.debug("Fetching schedule with access token")

    if mock?() do
      Logger.debug("Using mock schedule fetching")
      mock_fetch_schedule(access_token)
    else
      Logger.debug("Making real API schedule request")
      get("/api/v6/bookings?type=schedule&page=1&pageSize=100", headers: [{"authorization", "Bearer #{access_token}"}])
    end
  end

  @doc """
  Gets the current customer's information.
  Returns {:ok, response} with customer data on success.
  """
  def get_customer_info(access_token) do
    Logger.debug("Fetching customer info")

    if mock?() do
      Logger.debug("Using mock customer info")
      mock_get_customer_info(access_token)
    else
      Logger.debug("Making real API customer info request")
      get("/api/v6/customers/me", headers: [{"authorization", "Bearer #{access_token}"}])
    end
  end

  # Private helpers

  defp mock?() do
    # Only use mock in test environment
    env = Application.get_env(:schedshare, :env, :dev)
    Logger.debug("Current environment: #{env}")
    env == :test
  end

  # Mock API implementations for development and testing
  defp mock_authenticate(username, password) do
    if String.contains?(username, "test") || String.contains?(password, "test") do
      Logger.debug("Mock: Successful authentication")

      {:ok, %Tesla.Env{
        status: 200,
        body: %{
          "access_token" => "mock_access_token",
          "refresh_token" => "mock_refresh_token",
          "expires_in" => 3600,
          "token_type" => "Bearer"
        }
      }}
    else
      Logger.debug("Mock: Failed authentication for user #{username}")

      {:ok, %Tesla.Env{
        status: 401,
        body: %{
          "error" => "invalid_credentials",
          "error_description" => "The provided credentials are invalid"
        }
      }}
    end
  end

  defp mock_refresh_token(refresh_token) do
    if refresh_token == "mock_refresh_token" do
      Logger.debug("Mock: Successful token refresh")

      {:ok, %Tesla.Env{
        status: 200,
        body: %{
          "access_token" => "mock_access_token_new",
          "refresh_token" => "mock_refresh_token_new",
          "expires_in" => 3600,
          "token_type" => "Bearer"
        }
      }}
    else
      Logger.debug("Mock: Failed token refresh")

      {:ok, %Tesla.Env{
        status: 401,
        body: %{
          "error" => "invalid_token",
          "error_description" => "The refresh token is invalid or has expired"
        }
      }}
    end
  end

  defp mock_fetch_schedule("mock_access_token") do
    Logger.debug("Mock: Successful schedule fetch")

    now = DateTime.utc_now()
    tomorrow = DateTime.add(now, 24 * 3600, :second)

    {:ok, %Tesla.Env{
      status: 200,
      body: %{
        "data" => %{
          "bookings" => [
            %{
              "id" => "1",
              "status" => "CONFIRMED",
              "title" => "Yoga Class",
              "location" => "Mock Studio",
              "activity_type" => "Yoga",
              "start_time" => DateTime.to_iso8601(now),
              "end_time" => DateTime.to_iso8601(DateTime.add(now, 3600, :second)),
              "teacher_name" => "John Doe"
            },
            %{
              "id" => "2",
              "status" => "CONFIRMED",
              "title" => "HIIT Training",
              "location" => "Mock Gym",
              "activity_type" => "Fitness",
              "start_time" => DateTime.to_iso8601(tomorrow),
              "end_time" => DateTime.to_iso8601(DateTime.add(tomorrow, 3600, :second)),
              "teacher_name" => "Jane Smith"
            }
          ]
        }
      }
    }}
  end

  defp mock_fetch_schedule(token) do
    Logger.debug("Mock: Failed schedule fetch with token: #{token}")

    {:ok, %Tesla.Env{
      status: 401,
      body: %{
        "error" => "invalid_token",
        "error_description" => "The access token is invalid or has expired"
      }
    }}
  end

  defp mock_get_customer_info("mock_access_token") do
    Logger.debug("Mock: Successful customer info fetch")

    {:ok, %Tesla.Env{
      status: 200,
      body: %{
        "id" => "1",
        "name" => "Test Customer",
        "email" => "test@example.com"
      }
    }}
  end

  defp mock_get_customer_info(_token) do
    Logger.debug("Mock: Failed customer info fetch")

    {:ok, %Tesla.Env{
      status: 401,
      body: %{
        "error" => "invalid_token",
        "error_description" => "The access token is invalid or has expired"
      }
    }}
  end
end
