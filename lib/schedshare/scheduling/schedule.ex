defmodule Schedshare.Scheduling.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    belongs_to :user, Schedshare.Accounts.User
    has_many :bookings, Schedshare.Scheduling.Booking

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
  end
end
