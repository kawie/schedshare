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
      try do
        response = post("/api/v7/auth/token", %{
          grant_type: "password",
          username: username,
          password: password,
          client_id: System.get_env("API_CLIENT_ID"),
          client_secret: System.get_env("API_CLIENT_SECRET")
        })

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise "Authentication failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Authentication request failed: #{inspect(reason)}"
        end
      rescue
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{username: username})
          {:error, e}
      end
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
      try do
        response = post("/api/v7/auth/token", %{
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: System.get_env("API_CLIENT_ID"),
          client_secret: System.get_env("API_CLIENT_SECRET")
        })

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise "Token refresh failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Token refresh request failed: #{inspect(reason)}"
        end
      rescue
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, e}
      end
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
      try do
        response = get("/api/v6/bookings?type=schedule&page=1&pageSize=100", headers: [{"authorization", "Bearer #{access_token}"}])

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise RuntimeError, message: "Schedule fetch failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Schedule fetch request failed: #{inspect(reason)}"
        end
      rescue
        e in RuntimeError ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, e}
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, RuntimeError.exception(message: "Unexpected error: #{inspect(e)}")}
      end
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
      try do
        response = get("/api/v6/customers/me", headers: [{"authorization", "Bearer #{access_token}"}])

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise "Customer info fetch failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Customer info fetch request failed: #{inspect(reason)}"
        end
      rescue
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, e}
      end
    end
  end

  @doc """
  Fetches the user's waitlist from the API.
  Returns {:ok, response} with the waitlist data on success.
  """
  def fetch_waitlist(access_token) do
    Logger.debug("Fetching waitlist with access token")

    if mock?() do
      Logger.debug("Using mock waitlist fetching")
      mock_fetch_waitlist(access_token)
    else
      Logger.debug("Making real API waitlist request")
      try do
        response = get("/api/v6/customers/waitlist", headers: [{"authorization", "Bearer #{access_token}"}])

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise RuntimeError, message: "Waitlist fetch failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Waitlist fetch request failed: #{inspect(reason)}"
        end
      rescue
        e in RuntimeError ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, e}
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, RuntimeError.exception(message: "Unexpected error: #{inspect(e)}")}
      end
    end
  end

  @doc """
  Fetches course details for given course IDs from the API.
  Returns {:ok, response} with the course details on success.
  """
  def fetch_course_details(access_token, course_ids) when is_list(course_ids) and length(course_ids) > 0 do
    Logger.debug("Fetching course details for course IDs: #{inspect(course_ids)}")

    if mock?() do
      Logger.debug("Using mock course details fetching")
      mock_fetch_course_details(access_token, course_ids)
    else
      Logger.debug("Making real API course details request")
      try do
        # Build query parameters for course IDs
        query_params = course_ids
        |> Enum.map(fn id -> "ids%5B%5D=#{id}" end)
        |> Enum.join("&")
        |> Kernel.<>("&forDurationOfDays=14")

        response = get("/api/v6/courses?#{query_params}", headers: [{"authorization", "Bearer #{access_token}"}])

        case response do
          {:ok, %{status: 200} = resp} -> {:ok, resp}
          {:ok, resp} ->
            raise RuntimeError, message: "Course details fetch failed with status #{resp.status}"
          {:error, reason} ->
            raise RuntimeError, message: "Course details fetch request failed: #{inspect(reason)}"
        end
      rescue
        e in RuntimeError ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, e}
        e ->
          ErrorTracker.report(e, __STACKTRACE__, %{})
          {:error, RuntimeError.exception(message: "Unexpected error: #{inspect(e)}")}
      end
    end
  end

  def fetch_course_details(_access_token, []) do
    # Return empty result if no course IDs provided
    {:ok, %Tesla.Env{status: 200, body: %{"success" => "true", "data" => %{"classes" => [], "classesCount" => 0, "freeTrainings" => [], "freeTrainingsCount" => 0}}}}
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

  defp mock_fetch_waitlist("mock_access_token") do
    Logger.debug("Mock: Successful waitlist fetch")

    {:ok, %Tesla.Env{
      status: 200,
      body: %{
        "success" => "true",
        "data" => [
          92065566,
          92065567
        ]
      }
    }}
  end

  defp mock_fetch_waitlist(_token) do
    Logger.debug("Mock: Failed waitlist fetch")

    {:ok, %Tesla.Env{
      status: 401,
      body: %{
        "error" => "invalid_token",
        "error_description" => "The access token is invalid or has expired"
      }
    }}
  end

  defp mock_fetch_course_details("mock_access_token", course_ids) do
    Logger.debug("Mock: Successful course details fetch for #{inspect(course_ids)}")

    now = DateTime.utc_now()
    tomorrow = DateTime.add(now, 24 * 3600, :second)

    {:ok, %Tesla.Env{
      status: 200,
      body: %{
        "success" => "true",
        "data" => %{
          "classes" => [
            %{
              "id" => 92065566,
              "date" => "2025-08-02",
              "title" => "Full Body Strength",
              "startTime" => "11:15:00",
              "startDateTimeUTC" => "2025-08-02T11:15:00+02:00",
              "endTime" => "12:00:00",
              "endDateTimeUTC" => "2025-08-02T12:00:00+02:00",
              "venue" => %{
                "id" => 27168,
                "name" => "LIFTED - Studio Eberswalder",
                "location" => %{
                  "displayAddress" => "Berlin - Prenzlauer Berg",
                  "city" => %{
                    "id" => 1,
                    "name" => "Berlin"
                  },
                  "district" => %{
                    "id" => 85,
                    "name" => "Prenzlauer Berg",
                    "area" => "Berlin"
                  },
                  "latitude" => 52.542156400000003,
                  "longitude" => 13.4126598,
                  "postalCode" => "10437",
                  "address" => "Schönhauser Allee 48",
                  "country" => %{
                    "code" => "DE"
                  }
                },
                "phone" => "",
                "website" => "https://lifted-studios.com",
                "openingHoursText" => "Die Öffnungszeiten hängen von den Kurszeiten / vereinbarten Terminen ab oder sind nicht bekannt. Weitere Informationen findest du auf der Partner-Webseite.",
                "bookingLimitsText" => "M & L-Mitglieder können 8 Mal pro Monat Lifted - Eberswalder besuchen.\r\n\r\nXL-Mitglieder können 1x pro Tag Lifted - Eberswalder besuchen.",
                "importantInfo" => "++ENGLISH (German further below)++\nIf it is your 1st time at LIFTED, please be changed and ready on the training floor at least 10 minutes before class starts, as we need to give you a short intro. \n\nPlease also bring clean indoor training shoes and a towel! \nThis location has changing rooms but no showers.\n\nAll of our classes are taught in English, but a lot of trainers speak German too.\n\n++GERMAN++\nFalls du das erste Mal bei LIFTED bist, sei bitte mind. 10 Minuten vor Kursbeginn umgezogen und auf der Fläche damit wir dir ein kurzes Intro geben können.\n\nBitte denk immer daran saubere Trainingsschuhe und ein Handtuch mitzubringen. \nAn diesem Standort haben wir Umkleideräume, aber leider keine Duschen.\n\nAlle unsere Klassen sind in Englisch, aber viele TrainerInnen sprechen auch Deutsch.\n\nBuche deinen Kurs direkt über die Urban Sports Club App! Bitte beachte, dass dies eine verbindliche Buchung ist, und die Stornierungsfrist von 12 Stunden eingehalten werden muss. Dies wird dir auch bei der Buchung angezeigt. Andernfalls wird dir der Besuch von deinem monatlichen Besuchslimit abgezogen und in Rechnung gestellt. \n\nHinweis: Der Check-In Prozess über den QR Code vor Ort bleibt unverändert.",
                "additionalInformation" => "",
                "allowedBusinessTypes" => [
                  "b2c",
                  "b2b"
                ]
              },
              "category" => %{
                "id" => 233,
                "name" => "Functional Training",
                "icon" => "https://storage.googleapis.com/download/storage/v1/b/usc-pro-uscweb-live-media/o/categories%2FcategoryIcon_80x80_icon-category-functional-training.png?generation=1752493602308960&alt=media"
              },
              "extraPriceDescriptionText" => "",
              "covers" => [
                %{
                  "thumbnail" => "https://storage.googleapis.com/download/storage/v1/b/usc-pro-uscweb-live-media/o/venues%2Fthumbnail_150x150_x4dq3hjub8wrsgnhsvm2_1735901084667145.png?generation=1751993139379069&alt=media",
                  "original" => "https://storage.googleapis.com/download/storage/v1/b/usc-pro-uscweb-live-media/o/venues%2Foriginal_1200x675_x4dq3hjub8wrsgnhsvm2_1735901084667145.png?generation=1751993139337816&alt=media"
                }
              ],
              "planTypes" => [
                "M",
                "L",
                "XL"
              ],
              "planTypesB2B" => [
                "M",
                "L",
                "XL"
              ],
              "external" => true,
              "serviceType" => "event",
              "bookingType" => "confirmation_required",
              "types" => [
                "onsite"
              ],
              "isOnline" => 0,
              "isPlusCheckin" => 0,
              "isMyClubs" => false,
              "deleted" => 0,
              "highlight" => 0,
              "booking" => nil,
              "teacherName" => "Deon C.",
              "bookable" => 0,
              "minimumNumber" => -1,
              "maximumNumber" => 27,
              "freeSpots" => 0
            }
          ],
          "classesCount" => 1,
          "freeTrainings" => [],
          "freeTrainingsCount" => 0
        }
      }
    }}
  end

  defp mock_fetch_course_details(_token, _course_ids) do
    Logger.debug("Mock: Failed course details fetch")

    {:ok, %Tesla.Env{
      status: 401,
      body: %{
        "error" => "invalid_token",
        "error_description" => "The access token is invalid or has expired"
      }
    }}
  end
end
