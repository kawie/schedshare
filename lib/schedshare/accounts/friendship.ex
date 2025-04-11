defmodule Schedshare.Accounts.Friendship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Schedshare.Accounts.User

  schema "friendships" do
    belongs_to :user1, User
    belongs_to :user2, User
    belongs_to :requested_by, User
    field :status, Ecto.Enum, values: [:pending, :accepted, :rejected], default: :pending

    timestamps(type: :utc_datetime)
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:user1_id, :user2_id, :status, :requested_by_id])
    |> validate_required([:user1_id, :user2_id, :status])
    |> validate_different_users()
    |> ensure_ordered_ids()
    |> unique_constraint([:user1_id, :user2_id], name: :friendships_user1_id_user2_id_index)
    |> unique_constraint([:user2_id, :user1_id], name: :friendships_user2_id_user1_id_index)
  end

  defp validate_different_users(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id == user2_id do
      add_error(changeset, :user1_id, "cannot be friends with yourself")
    else
      changeset
    end
  end

  defp ensure_ordered_ids(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id > user2_id do
      changeset
      |> put_change(:user1_id, user2_id)
      |> put_change(:user2_id, user1_id)
    else
      changeset
    end
  end
end
