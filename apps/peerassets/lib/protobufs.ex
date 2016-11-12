defmodule Mercator.PeerAssets.Protobufs do
  use Protobuf, from: Path.wildcard(Application.app_dir(:peerassets, ["priv", "*.proto"]))
end
