defmodule BitcoinTool do

  @bitcoin_tool_bin Application.app_dir(:bitcoin_tool_ex, ["priv", "bitcoin-tool"])

  def create_worker!(name, config) do
    Supervisor.Spec.worker(:stdinout_pool_server,
                           [name, config |> build_cmd],
                           id: Atom.to_string(name))
  end

  def start_link(name, config) do
    :stdinout.start_link(name, config |> build_cmd)
  end

  def process!(data, name) do
    case name |> :stdinout.send(data |> String.to_char_list) do
      {:stdout, response} -> response
      {:stderr, [error]} ->  raise BitcoinToolError, message: error
    end
  end

  defp build_cmd(config) do
    @bitcoin_tool_bin <>
      " --input-file -" <>
      " --input-type " <> config.input_type <>
      " --input-format " <> config.input_format <>
      " --network " <> config.network <>
      " --output-type all" <>
      " --public-key-compression " <> config.public_key_compression
    |> String.to_char_list
  end

end

defmodule BitcoinToolError do
  defexception message: "Error returned from bitcoin-tool"
end
