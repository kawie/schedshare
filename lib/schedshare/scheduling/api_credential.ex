defmodule Schedshare.Scheduling.ApiCredential do
  use Ecto.Schema
  import Ecto.Changeset

  alias Schedshare.Crypto

  schema "api_credentials" do
    field :username, :string
    field :password, :string
    field :access_token, :string
    field :refresh_token, :string
    field :token_expires_at, :utc_datetime_usec
    field :last_sync_at, :utc_datetime_usec
    field :connection_status, :string
    field :connection_error, :string
    field :plaintext_password, :string, virtual: true

    belongs_to :user, Schedshare.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(api_credential, attrs) do
    api_credential
    |> cast(attrs, [:username, :password, :access_token, :refresh_token, :token_expires_at, :last_sync_at, :connection_status, :connection_error, :plaintext_password])
    |> validate_required([:username])
    |> maybe_encrypt_password()
  end

  defp maybe_encrypt_password(changeset) do
    case get_change(changeset, :plaintext_password) do
      nil -> changeset
      plaintext_password ->
        encrypted_password = Crypto.encrypt(plaintext_password)
        put_change(changeset, :password, encrypted_password)
    end
  end
end
