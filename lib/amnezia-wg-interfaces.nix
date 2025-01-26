{
  config,
  lib,
  ...
}: let
  exports = config.networking.amnezia-wg.exports;

  # Функция возвращает всех пиров, у которых есть настройка для iface.name
  peersForInterface = iface:
    builtins.attrValues (
      lib.filterAttrs (_: peer: peer.networks ? ${iface.name}) exports.peers
    );

  peerToConfig = iface: peer: let
    net = peer.networks.${iface.name};
  in {
    name = peer.name;
    publicKey = peer.publicKey;
    allowedIPs = lib.concatStringsSep ", " ([net.address] ++ net.allowedNetworks);
    persistentKeepalive = net.persistentKeepalive;
    endpoint = net.endpoint;
  };

  mkInterface = iface: {
    name = iface.name;
    address = iface.address;
    port = iface.port;
    mtu = iface.mtu;
    peers = map (peer: peerToConfig iface peer) (peersForInterface iface);
  };
in {
  mkAmneziaWgInterfaces = interfaces: map mkInterface interfaces;
}
