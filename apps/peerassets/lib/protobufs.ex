defmodule Mercator.PeerAssets.Protobufs do
  use Protobuf, "
syntax = \"proto3\";

// PeerAssets transaction data specification
// written by hrobeers (github.com/hrobeers)

// Meta-data message for the deck spawn transaction
message DeckSpawn {
  // Protocol version number
  uint32 version = 1;

  // Short name for the registered asset
  string short_name = 2;

  // Number of decimals to define how much an asset can divided
  uint32 number_of_decimals = 3;

  // Modes for asset issuance
  enum MODE {
    NONE   = 0x00; // No issuance allowed
    CUSTOM = 0x01; // Not specified, custom client implementation needed
    ONCE   = 0x02; // Only one issuance transaction from asset owner allowed
    MULTI  = 0x04; // Multiple issuance transactions from asset owner allowed
  }
  uint32 issue_mode = 4;

  // Free form asset specific data (optional)
  bytes asset_specific_data = 5;
}

// Transaction data for:
// - Card transfer transaction
// - Card issue transaction
// - Card burn transaction
message CardTransfer {
  // Protocol version number
  uint32 version = 1;

  // Amount to transfer
  uint64 amount = 2;

  // Number of decimals
  // Should be equal to the number specified in the deck spawn transaction.
  // Encoded in this message for easy validation
  uint32 number_of_decimals = 3;

  // Free form asset specific data (optional)
  bytes asset_specific_data = 4;
}
"
end
