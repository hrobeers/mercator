defmodule BitcoinTool.Result do

  defstruct address_hex: nil,
            address_base58: nil,
            address_base58check: nil,
            public_key_ripemd160_hex: nil,
            public_key_ripemd160_base58: nil,
            public_key_ripemd160_base58check: nil,
            public_key_sha256_hex: nil,
            public_key_sha256_base58: nil,
            public_key_sha256_base58check: nil,
            public_key_hex: nil,
            public_key_base58: nil,
            public_key_base58check: nil,
            private_key_wif_hex: nil,
            private_key_wif_base58: nil,
            private_key_wif_base58check: nil,
            private_key_hex: nil,
            private_key_base58: nil,
            private_key_base58check: nil

  def parse(data) do
    <<"address.hex:", address_hex :: bytes-size(42),
    "address.base58:", address_base58 :: bytes-size(29),
    "address.base58check:", address_base58check :: bytes-size(34),
    data :: binary >> = data

    { public_key_ripemd160_hex, public_key_ripemd160_base58, public_key_ripemd160_base58check, data } = data
    |> parse_public_key_ripemd160

    { public_key_sha256_hex, public_key_sha256_base58, public_key_sha256_base58check, data } = data
    |> parse_public_key_sha256

    { public_key_hex, public_key_base58, public_key_base58check, data } = data
    |> parse_public_key

    { private_key_wif_hex, private_key_wif_base58, private_key_wif_base58check, data } = data
    |> parse_private_key_wif

    { private_key_hex, private_key_base58, private_key_base58check, data } = data
    |> parse_private_key

    %BitcoinTool.Result{
      address_hex: address_hex,
      address_base58: address_base58,
      address_base58check: address_base58check,
      public_key_ripemd160_hex: public_key_ripemd160_hex,
      public_key_ripemd160_base58: public_key_ripemd160_base58,
      public_key_ripemd160_base58check: public_key_ripemd160_base58check,
      public_key_sha256_hex: public_key_sha256_hex,
      public_key_sha256_base58: public_key_sha256_base58,
      public_key_sha256_base58check: public_key_sha256_base58check,
      public_key_hex: public_key_hex,
      public_key_base58: public_key_base58,
      public_key_base58check: public_key_base58check,
      private_key_wif_hex: private_key_wif_hex,
      private_key_wif_base58: private_key_wif_base58,
      private_key_wif_base58check: private_key_wif_base58check,
      private_key_hex: private_key_hex,
      private_key_base58: private_key_base58,
      private_key_base58check: private_key_base58check
    }
  end

  defp parse_public_key_ripemd160(data) do
    case data do
      # Compressed
      <<"public-key-ripemd160.hex:", hex :: bytes-size(40),
      "public-key-ripemd160.base58:", base58 :: bytes-size(28),
      "public-key-ripemd160.base58check:", base58check :: bytes-size(33), data :: binary >>
        -> { hex, base58, base58check, data }

      # Uncompressed
      <<"public-key-ripemd160.hex:", hex :: bytes-size(40),
      "public-key-ripemd160.base58:", base58 :: bytes-size(27),
      "public-key-ripemd160.base58check:", base58check :: bytes-size(33), data :: binary >>
        -> { hex, base58, base58check, data }

      # Not available
      _ -> { nil, nil, nil, data }
    end
  end

  defp parse_public_key_sha256(data) do
    case data do
      # Compressed
      <<"public-key-sha256.hex:", hex :: bytes-size(64),
      "public-key-sha256.base58:", base58 :: bytes-size(44),
      "public-key-sha256.base58check:", base58check :: bytes-size(50), data :: binary >>
        -> { hex, base58, base58check, data }

      # Uncompressed
      <<"public-key-sha256.hex:", hex :: bytes-size(131),
      "public-key-sha256.base58:", base58 :: bytes-size(89),
      "public-key-sha256.base58check:", base58check :: bytes-size(95), data :: binary >>
        -> { hex, base58, base58check, data }

      # Not available
      _ -> { nil, nil, nil, data }
    end
  end

  defp parse_public_key(data) do
    case data do
      # Compressed
      <<"public-key.hex:", hex :: bytes-size(66),
      "public-key.base58:", base58 :: bytes-size(44),
      "public-key.base58check:", base58check :: bytes-size(50), data :: binary >>
        -> { hex, base58, base58check, data }

      # Uncompressed
      <<"public-key.hex:", hex :: bytes-size(130),
      "public-key.base58:", base58 :: bytes-size(88),
      "public-key.base58check:", base58check :: bytes-size(94), data :: binary >>
        -> { hex, base58, base58check, data }

      # Not available
      _ -> { nil, nil, nil, data }
    end
  end

  defp parse_private_key_wif(data) do
    case data do
      # Compressed
      <<"private-key-wif.hex:", hex :: bytes-size(68),
      "private-key-wif.base58:", base58 :: bytes-size(47),
      "private-key-wif.base58check:", base58check :: bytes-size(52), data :: binary >>
        -> { hex, base58, base58check, data }

      # Uncompressed
      <<"private-key-wif.hex:", hex :: bytes-size(66),
      "private-key-wif.base58:", base58 :: bytes-size(45),
      "private-key-wif.base58check:", base58check :: bytes-size(51), data :: binary >>
        -> { hex, base58, base58check, data }

      # Not available
      _ -> { nil, nil, nil, data }
    end
  end

  defp parse_private_key(data) do
    case data do
      <<"private-key.hex:", hex :: bytes-size(64),
      "private-key.base58:", base58 :: bytes-size(44),
      "private-key.base58check:", base58check :: bytes-size(50), data :: binary >>
        -> { hex, base58, base58check, data }

      # Not available
      _ -> { nil, nil, nil, data }
    end
  end
end
