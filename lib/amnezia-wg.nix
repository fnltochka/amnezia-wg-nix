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
            description = "Приватный ключ WireGuard (сервер).";
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Публичный ключ WireGuard (сервер).";
          };
          publicIP = lib.mkOption {
            type = lib.types.str;
            description = "Публичный IP/домен сервера.";
          };
          interfaces = lib.mkOption {
            # Важно: types.nix в том же каталоге, и мы передаём {inherit lib;}
            type = lib.types.listOf (import ./types.nix {inherit lib;}).amneziaWgInterfaceType;
            description = "Список интерфейсов (серверных).";
            default = [];
          };
          peers = lib.mkOption {
            type = lib.types.attrsOf (import ./types.nix {inherit lib;}).amneziaWgPeerType;
            description = "Список пиров (по имени).";
            default = {};
          };
        };
      };
      description = "Amnezia WG: параметры WireGuard (ключи, интерфейсы, peers).";
    };

    # Обработанные интерфейсы
    processedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = interfacesLib.mkAmneziaWgInterfaces cfg.exports.interfaces;
    };
  };

  config = let
    allIfaces = cfg.processedInterfaces;
    # ссылка на tools
    amneziaTools = pkgs.unstable.amneziawg-tools;
  in {
    environment.systemPackages = with pkgs; [
      amneziaTools
      iptables
      iproute2
      bash
    ];

    # Подключаем модуль amneziawg, если он есть
    boot.extraModulePackages = [
      config.boot.kernelPackages.amneziawg
    ];
    boot.kernelModules = ["amneziawg"];

    environment.etc = lib.mkMerge [
      {
        # Private/public key
        "amneziawg/private.key".text = cfg.exports.privateKey;
        "amneziawg/public.key".text = cfg.exports.publicKey;
      }
      # Server configs
      (builtins.listToAttrs (map (iface: {
          name = "amneziawg/${iface.name}.conf";
          value = {
            text = configLib.generateServerConfig iface;
            mode = "0600";
          };
        })
        allIfaces))
      # Client configs
      (builtins.listToAttrs (lib.flatten (map (
          iface:
            map (peer: {
              name = "amneziawg/clients/${iface.name}-${peer.name}.conf";
              value = {
                text = configLib.generateClientConfig iface peer;
                mode = "0600";
              };
            })
            iface.peers
        )
        allIfaces)))
    ];

    # Создаём сервис для каждого интерфейса
    systemd.services = lib.mkMerge [
      (builtins.listToAttrs (map (iface: {
          name = "amnezia-wg-${iface.name}";
          value = {
            description = "Amnezia WG Interface ${iface.name}";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStartPre = ''
                ${pkgs.bash}/bin/bash -c '${pkgs.iproute2}/bin/ip link delete ${iface.name} 2>/dev/null || :'
              '';
              ExecStart = "${amneziaTools}/bin/awg-quick up /etc/amneziawg/${iface.name}.conf";
              ExecStop = "${amneziaTools}/bin/awg-quick down /etc/amneziawg/${iface.name}.conf";
            };
          };
        })
        allIfaces))
    ];

    # Открываем UDP порты для WG интерфейсов
    networking.firewall = {
      enable = true;
      allowedUDPPorts = map (i: i.port) allIfaces;
      allowedTCPPorts = [];
      checkReversePath = "loose";
    };
  };
}
