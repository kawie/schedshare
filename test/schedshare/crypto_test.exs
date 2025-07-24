defmodule Schedshare.CryptoTest do
  use Schedshare.DataCase

  alias Schedshare.Crypto
  alias Schedshare.Scheduling.ApiCredential

  test "encrypt/1 and decrypt/1 work correctly" do
    plaintext = "my-secret-password"
    encrypted = Crypto.encrypt(plaintext)
    decrypted = Crypto.decrypt(encrypted)

    assert encrypted != plaintext
    assert decrypted == plaintext
  end

  test "ApiCredential changeset encrypts plaintext_password" do
    user = %Schedshare.Accounts.User{id: 1}
    api_credential = %ApiCredential{user: user}

    attrs = %{
      "username" => "testuser",
      "plaintext_password" => "my-secret-password"
    }

    changeset = ApiCredential.changeset(api_credential, attrs)

    assert changeset.valid?
    assert get_change(changeset, :username) == "testuser"
    assert get_change(changeset, :password) != "my-secret-password"
    assert get_change(changeset, :password) != nil

    # Verify the encrypted password can be decrypted
    encrypted_password = get_change(changeset, :password)
    decrypted = Crypto.decrypt(encrypted_password)
    assert decrypted == "my-secret-password"
  end
end
