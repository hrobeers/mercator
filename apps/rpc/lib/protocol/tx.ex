defmodule Bitcoin.Protocol.Types.Tx do

  @moduledoc """
    tx describes a bitcoin transaction, in reply to getdata.

    https://en.bitcoin.it/wiki/Protocol_documentation#tx
  """

  alias Bitcoin.Protocol.Types.Integer
  alias Bitcoin.Protocol.Types.TransactionInput
  alias Bitcoin.Protocol.Types.TransactionOutput

  defstruct txid: nil,   # Transaction id (hexadecimal)
            version: 0,  # Transaction data format version
            timestamp: 0,# Transaction timestamp, only available on ppcoin forks
            inputs: [],  # A list of 1 or more transaction inputs or sources for coins
            outputs: [], # A list of 1 or more transaction outputs or destinations for coins
            lock_time: 0 # The block number or timestamp at which this transaction is locked:
                         #   0 - Not Locked
                         #   < 500000000 - Block number at which this transaction is locked
                         #   >= 500000000 - UNIX timestamp at which this transaction is locked
                         # If all TxIn inputs have final (0xffffffff) sequence numbers then lock_time is irrelevant.
                         # Otherwise, the transaction may not be added to a block until after lock_time (see NLockTime).

  @type t :: %Bitcoin.Protocol.Types.Tx{
    version: non_neg_integer,
    inputs: [],
    outputs: [],
    lock_time: non_neg_integer
  }

  # TODO: calculate txid from data
  def parse(data, txid) do
    parse(data, txid, false)
  end

  def parse(data, txid, has_timestamp) do

    {version, timestamp, payload} = parse_version_and_timestamp(data, has_timestamp)

    [tx_in_count, payload] = Integer.parse_stream(payload)

    [transaction_inputs, payload] = Enum.reduce(1..tx_in_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = TransactionInput.parse_stream(payload)
      [collection ++ [element], payload]
    end)

    [tx_out_count, payload] = Integer.parse_stream(payload)

    [transaction_outputs, payload] = Enum.reduce(1..tx_out_count, [[], payload], fn (_, [collection, payload]) ->
      [element, payload] = TransactionOutput.parse_stream(payload)
      [collection ++ [element], payload]
    end)

    <<lock_time::unsigned-little-integer-size(32)>> = payload

    %Bitcoin.Protocol.Types.Tx{
      txid: txid,
      version: version,
      timestamp: timestamp,
      inputs: transaction_inputs,
      outputs: transaction_outputs,
      lock_time: lock_time
    }

  end

  defp parse_version_and_timestamp(data, has_timestamp) do
    case has_timestamp do
      true ->
        <<version :: unsigned-little-integer-size(32), payload :: binary>> = data
        <<timestamp :: unsigned-little-integer-size(32), payload :: binary>> = payload
        {version, timestamp, payload}
      false ->
        <<version :: unsigned-little-integer-size(32), payload :: binary>> = data
        {version, nil, payload}
    end
  end

end
