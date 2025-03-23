defmodule Schedshare.Scheduling.ScheduleSyncServer do
  use GenServer
  require Logger

  # 15 minutes in prod/release, 1 minute in dev
  @check_interval (if Mix.env() == :dev do
    1 * 60 * 1000  # 1 minute in dev
  else
    15 * 60 * 1000 # 15 minutes in prod/release
  end)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    # Send an immediate check message
    send(self(), :check_schedules)
    # Also schedule the next check
    schedule_check()
    {:ok, %{}}
  end

  def handle_info(:check_schedules, state) do
    # Get all users that need syncing
    users_needing_sync = Schedshare.Accounts.list_users()

    # Sync each user and their following
    users_needing_sync
    |> Enum.map(fn user ->
      case Schedshare.Scheduling.Sync.sync_user_and_following(user.id) do
        %{success: s, error: e} = result when s > 0 or e > 0 ->
          Logger.info("Background sync for user #{user.id}: #{s} succeeded, #{e} failed")
          result
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)

    # Schedule next check
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_schedules, @check_interval)
  end
end
