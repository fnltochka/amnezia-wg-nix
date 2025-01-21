{
  config,
  lib,
  ...
}: let
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

  generateClientConfig = iface: peer: let
    network = peer.networks.${iface.name};
    endpoint = network.endpoint or "${network.publicIP or config.networking.amnezia-wg.exports.publicIP}:${iface.port}";
  in
    lib.strings.concat [
      "[Interface]"
      (lib.concatMapStrings "\n" (kv: "${kv.key} = ${kv.value}") baseConfig)
      "PrivateKey = ${peer.privateKey or "REPLACE_WITH_CLIENT_PRIVATE_KEY"}"
      "Address = ${network.address}"
      "ListenPort = ${iface.port}"

      "[Peer]"
      "PublicKey = ${config.networking.amnezia-wg.exports.publicKey}"
      "AllowedIPs = ${lib.concatStringsSep ", " network.allowedNetworks}"
      "Endpoint = ${endpoint}"
      "PersistentKeepalive = ${network.persistentKeepalive}"
    ];

  generateServerConfig = iface:
    lib.strings.concat [
      "[Interface]"
      "PrivateKey = ${config.networking.amnezia-wg.exports.privateKey}"
      "Address = ${iface.address}"
      "ListenPort = ${iface.port}"
      (lib.optionalString iface.mtu "MTU = ${iface.mtu}")
    ]
    ++ lib.concatMapStrings "\n" (peer:
      lib.strings.concat [
        "[Peer]"
        "PublicKey = ${peer.publicKey}"
        "AllowedIPs = ${peer.allowedIPs}"
        (lib.optionalString peer.endpoint "Endpoint = ${peer.endpoint}")
        "PersistentKeepalive = ${peer.persistentKeepalive}"
      ])
    iface.peers;
in {
  inherit generateClientConfig generateServerConfig;
}
