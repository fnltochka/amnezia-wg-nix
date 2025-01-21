{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.amnezia-wg;
  configLib = import ./amnezia-wg-config.nix {inherit config lib;};
  interfacesLib = import ./amnezia-wg-interfaces.nix {inherit config lib;};
in {
  options.networking.amnezia-wg = {
    exports = lib.mkOption {
      type = lib.types.submodule {
        options = {
          privateKey = lib.mkOption {
            type = lib.types.str;
            description = "Приватный ключ узла Amnezia WG";
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Публичный ключ узла Amnezia WG";
          };
          publicIP = lib.mkOption {
            type = lib.types.str;
            description = "Публичный IP-адрес узла Amnezia WG";
          };
          interfaces = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            description = "Конфигурация интерфейсов Amnezia WG";
            default = [];
          };
          peers = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            description = "Конфигурация пиров для Amnezia WG";
            default = {};
          };
        };
      };
      description = "Экспорты Amnezia WG узла";
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Конфигурация интерфейсов Amnezia WG";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      unstable.amneziawg-tools
      iptables
      iproute2
      bash
    ];

    boot = {
      extraModulePackages = [config.boot.kernelPackages.amneziawg];
      kernelModules = ["amneziawg"];
    };

    environment.etc = lib.mkMerge [
      {
        "amneziawg/private.key".text = cfg.exports.privateKey;
        "amneziawg/public.key".text = cfg.exports.publicKey;
      }
      (lib.mapAttrs (name: iface: {
          name = "amneziawg/${iface.name}.conf";
          value = {
            text = configLib.generateServerConfig iface;
            mode = "0600";
          };
        })
        cfg.exports.interfaces)
      (lib.flatten (lib.mapAttrs (
          _: iface:
            lib.mapAttrs (peerName: peer: {
              name = "amneziawg/clients/${iface.name}-${peer.name}.conf";
              value = {
                text = configLib.generateClientConfig iface peer;
                mode = "0600";
              };
            })
            iface.peers
        )
        cfg.exports.interfaces))
    ];

    systemd.services = lib.mkMerge [
      (lib.mapAttrs (name: iface: {
          name = name;
          value = {
            description = "Amnezia WG Interface ${iface.name}";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.iproute2}/bin/ip link delete ${iface.name} 2>/dev/null || :'";
              ExecStart = "${pkgs.unstable.amneziawg-tools}/bin/awg-quick up /etc/amneziawg/${iface.name}.conf";
              ExecStop = "${pkgs.unstable.amneziawg-tools}/bin/awg-quick down /etc/amneziawg/${iface.name}.conf";
            };
          };
        })
        cfg.exports.interfaces)
    ];

    networking.firewall = {
      enable = true;
      allowedTCPPorts = lib.map (iface: iface.port) cfg.exports.interfaces;
      allowedUDPPorts = lib.map (iface: iface.port) cfg.exports.interfaces;
      checkReversePath = "loose";
    };
  };
}
