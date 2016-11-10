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

    <<"public-key-ripemd160.hex:", public_key_ripemd160_hex :: bytes-size(40),
    "public-key-ripemd160.base58:", public_key_ripemd160_base58 :: bytes-size(28),
    "public-key-ripemd160.base58check:", public_key_ripemd160_base58check :: bytes-size(33),
    data :: binary >> = data

    <<"public-key-sha256.hex:", public_key_sha256_hex :: bytes-size(64),
    "public-key-sha256.base58:", public_key_sha256_base58 :: bytes-size(44),
    "public-key-sha256.base58check:", public_key_sha256_base58check :: bytes-size(50),
    data :: binary >> = data

    <<"public-key.hex:", public_key_hex :: bytes-size(66),
    "public-key.base58:", public_key_base58 :: bytes-size(44),
    "public-key.base58check:", public_key_base58check :: bytes-size(50),
    data :: binary >> = data

    <<"private-key-wif.hex:", private_key_wif_hex :: bytes-size(68),
    "private-key-wif.base58:", private_key_wif_base58 :: bytes-size(47),
    "private-key-wif.base58check:", private_key_wif_base58check :: bytes-size(52),
    data :: binary >> = data

    <<"private-key.hex:", private_key_hex :: bytes-size(64),
    "private-key.base58:", private_key_base58 :: bytes-size(44),
    "private-key.base58check:", private_key_base58check :: bytes-size(50),
    data :: binary >> = data

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
end
