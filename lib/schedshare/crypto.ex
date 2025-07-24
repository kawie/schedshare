defmodule Schedshare.Crypto do
  @moduledoc """
  Handles encryption and decryption of data.
  """

  @key Application.compile_env!(:schedshare, :api_credential_encryption_key)
  # The API requires the IV to be the same as the key.
  # AES-128-CBC uses a 128-bit (16-byte) IV.
  @iv @key

  def encrypt(data) do
    padded_data = pad(data)
    cipher = :crypto.crypto_one_time(:aes_128_cbc, @key, @iv, padded_data, encrypt: true)
    Base.encode64(cipher)
  end

  def decrypt(encoded_data) do
    with {:ok, data} <- Base.decode64(encoded_data) do
      decrypted = :crypto.crypto_one_time(:aes_128_cbc, @key, @iv, data, encrypt: false)
      unpad(decrypted)
    end
  end

  # PKCS7 padding
  defp pad(data) do
    block_size = 16
    padding_length = block_size - rem(byte_size(data), block_size)
    padding = List.duplicate(padding_length, padding_length) |> :binary.list_to_bin()
    data <> padding
  end

  # Remove PKCS7 padding
  defp unpad(data) do
    padding_length = :binary.last(data)
    if padding_length > 0 and padding_length <= 16 do
      data_size = byte_size(data) - padding_length
      :binary.part(data, 0, data_size)
    else
      data
    end
  end
end
