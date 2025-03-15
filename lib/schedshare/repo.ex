defmodule Schedshare.Repo do
  use Ecto.Repo,
    otp_app: :schedshare,
    adapter: Ecto.Adapters.SQLite3
end
