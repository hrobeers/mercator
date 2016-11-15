defprotocol BitcoinTool.Protocols.Address do
  @doc "Returns the raw binary address"
  def raw(data)
  @doc "Returns the hex address"
  def hex(data)
  @doc "Returns the Base58Check encoded address (Default address encoding)"
  def base58check(data)
end
