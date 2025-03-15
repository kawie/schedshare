defmodule Schedshare.Accounts.Follow do
  use Ecto.Schema
  import Ecto.Changeset
  alias Schedshare.Accounts.User

  schema "follows" do
    belongs_to :follower, User
    belongs_to :followed, User
    field :status, Ecto.Enum, values: [:pending, :approved], default: :pending

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_id, :status])
    |> validate_required([:follower_id, :followed_id])
    |> unique_constraint([:follower_id, :followed_id], name: :follows_follower_id_followed_id_index)
    |> validate_different_users()
  end

  defp validate_different_users(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followed_id = get_field(changeset, :followed_id)

    if follower_id && followed_id && follower_id == followed_id do
      add_error(changeset, :follower_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
