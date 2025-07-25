defmodule Schedshare.Scheduling.HTTPClientTest do
  use ExUnit.Case, async: true
  alias Schedshare.Scheduling.HTTPClient

  setup do
    # Ensure we're in test mode
    Application.put_env(:schedshare, :env, :test)
    :ok
  end

  describe "authenticate/2" do
    test "returns success with valid test credentials" do
      assert {:ok, response} = HTTPClient.authenticate("test_user", "test_password")
      assert response.status == 200
      assert %{
        "access_token" => "mock_access_token",
        "refresh_token" => "mock_refresh_token",
        "expires_in" => 3600,
        "token_type" => "Bearer"
      } = response.body
    end

    test "returns error with invalid credentials" do
      assert {:ok, response} = HTTPClient.authenticate("invalid", "invalid")
      assert response.status == 401
      assert %{
        "error" => "invalid_credentials",
        "error_description" => "The provided credentials are invalid"
      } = response.body
    end
  end

  describe "fetch_schedule/1" do
    test "returns schedule with valid token" do
      assert {:ok, response} = HTTPClient.fetch_schedule("mock_access_token")
      assert response.status == 200
      assert %{"data" => %{"bookings" => [%{"id" => "1"} | _]}} = response.body
    end

    test "returns error with invalid token" do
      assert {:ok, response} = HTTPClient.fetch_schedule("invalid_token")
      assert response.status == 401
      assert %{
        "error" => "invalid_token",
        "error_description" => "The access token is invalid or has expired"
      } = response.body
    end

    test "returned bookings have the required fields" do
      assert {:ok, response} = HTTPClient.fetch_schedule("mock_access_token")
      assert %{"data" => %{"bookings" => [booking | _]}} = response.body

      required_fields = ~w(id title location activity_type start_time end_time)
      for field <- required_fields do
        assert Map.has_key?(booking, field), "Booking is missing required field: #{field}"
      end
    end
  end

  describe "fetch_waitlist/1" do
    test "returns waitlist data for valid token" do
      result = HTTPClient.fetch_waitlist("mock_access_token")

      assert {:ok, %Tesla.Env{status: 200, body: body}} = result
      assert body["success"] == "true"
      assert is_list(body["data"])
      assert length(body["data"]) > 0
    end

    test "returns error for invalid token" do
      result = HTTPClient.fetch_waitlist("invalid_token")

      assert {:ok, %Tesla.Env{status: 401, body: body}} = result
      assert body["error"] == "invalid_token"
    end
  end

  describe "fetch_course_details/2" do
    test "returns course details for valid course IDs" do
      course_ids = [92065566, 92065567]
      result = HTTPClient.fetch_course_details("mock_access_token", course_ids)

      assert {:ok, %Tesla.Env{status: 200, body: body}} = result
      assert body["success"] == "true"
      assert body["data"]["classesCount"] > 0
      assert is_list(body["data"]["classes"])
    end

    test "returns empty result for empty course IDs list" do
      result = HTTPClient.fetch_course_details("mock_access_token", [])

      assert {:ok, %Tesla.Env{status: 200, body: body}} = result
      assert body["success"] == "true"
      assert body["data"]["classesCount"] == 0
      assert body["data"]["classes"] == []
    end

    test "returns error for invalid token" do
      course_ids = [92065566]
      result = HTTPClient.fetch_course_details("invalid_token", course_ids)

      assert {:ok, %Tesla.Env{status: 401, body: body}} = result
      assert body["error"] == "invalid_token"
    end
  end
end
