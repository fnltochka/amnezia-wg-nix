{
  config,
  lib,
  ...
}: let
  # Базовые настройки для секции [Interface] в клиентском конфиге
  baseConfig = {
    Jc = 0;
    Jmin = 0;
    Jmax = 0;
    S1 = 0;
    S2 = 0;
    H1 = 1;
    H2 = 2;
    H3 = 3;
    H4 = 4;
  };

  generateServerConfig = iface: ''
    [Interface]
    PrivateKey = ${config.networking.amnezia-wg.exports.privateKey}
    Address = ${iface.address}
    ListenPort = ${toString iface.port}
    ${lib.optionalString (iface.mtu != null) ''
      MTU = ${toString iface.mtu}
    ''}

    ${lib.concatMapStrings (p: ''
        [Peer]
        PublicKey = ${p.publicKey}
        AllowedIPs = ${p.allowedIPs}
        ${lib.optionalString (p.endpoint != null) "Endpoint = ${p.endpoint}"}
        PersistentKeepalive = ${toString p.persistentKeepalive}
      '')
      iface.peers}
  '';

  generateClientConfig = iface: peer: ''
    [Interface]
    ${lib.concatMapStrings (kv: "${kv.key} = ${kv.value}\n") baseConfig}
    PrivateKey = ${peer.privateKey or "REPLACE_WITH_CLIENT_PRIVATE_KEY"}
    Address = ${peer.networks.${iface.name}.address}
    ListenPort = ${toString iface.port}

    [Peer]
    PublicKey = ${config.networking.amnezia-wg.exports.publicKey}
    AllowedIPs = ${lib.concatStringsSep ", " peer.networks.${iface.name}.allowedNetworks}
    Endpoint = ${peer.networks.${iface.name}.endpoint or "${config.networking.amnezia-wg.exports.publicIP}:${iface.port}"}
    PersistentKeepalive = ${toString peer.networks.${iface.name}.persistentKeepalive}
  '';
in {
  inherit generateServerConfig generateClientConfig;
}
