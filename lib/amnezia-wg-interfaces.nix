{
  config,
  lib,
  ...
}: let
  filterPeers = ifaceName: exports:
    lib.filterAttrs (name: peer: lib.hasAttr ifaceName peer.networks) exports.peers;

  transformPeer = ifaceName: peer: let
    network = peer.networks.${ifaceName};
  in {
    name = peer.name;
    publicKey = peer.publicKey;
    allowedIPs = lib.concatStringsSep ", " ([network.address] ++ network.allowedNetworks);
    persistentKeepalive = network.persistentKeepalive;
    endpoint = network.endpoint or null;
  };

  createInterface = exports: iface: {
    name = iface.name;
    address = iface.address;
    port = iface.port;
    peers = lib.attrValues (lib.mapAttrs (_: peer: transformPeer iface.name peer) (filterPeers iface.name exports));
  };
in {
  mkAmneziaWgInterfaces = exports: interfaces:
    map (iface: createInterface exports iface) interfaces;
}
