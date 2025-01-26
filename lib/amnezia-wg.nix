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
            description = "Приватный ключ WireGuard (server).";
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Публичный ключ WireGuard (server).";
          };
          publicIP = lib.mkOption {
            type = lib.types.str;
            description = "Публичный IP-адрес (или домен) узла WireGuard.";
          };
          interfaces = lib.mkOption {
            # ссылка на amneziaWgInterfaceType
            type = lib.types.listOf (import ./types.nix {inherit lib;}).amneziaWgInterfaceType;
            description = "Список интерфейсов WireGuard (на сервере).";
            default = [];
          };
          peers = lib.mkOption {
            # ссылка на amneziaWgPeerType
            type = lib.types.attrsOf (import ./types.nix {inherit lib;}).amneziaWgPeerType;
            description = "Список пиров (по имени).";
            default = {};
          };
        };
      };
      description = "WireGuard параметры (Amnezia WG).";
    };

    processedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = interfacesLib.mkAmneziaWgInterfaces cfg.exports.interfaces;
    };
  };

  config = let
    allIfaces = cfg.processedInterfaces;
  in {
    # Ставим нужные пакеты
    environment.systemPackages = with pkgs; [
      (pkgs.unstable.amneziawg-tools or pkgs.amneziawg-tools)
      iptables
      iproute2
      bash
    ];

    # Модули ядра: amneziawg (при наличии)
    boot.extraModulePackages = [(config.boot.kernelPackages.amneziawg or null)];
    boot.kernelModules = ["amneziawg"];

    # Генерируем файлы /etc/amneziawg/...
    environment.etc = lib.mkMerge [
      {
        # Private key + public key
        "amneziawg/private.key".text = cfg.exports.privateKey;
        "amneziawg/public.key".text = cfg.exports.publicKey;
      }
      # Серверная конфигурация
      (builtins.listToAttrs (map (iface: {
          name = "amneziawg/${iface.name}.conf";
          value = {
            text = configLib.generateServerConfig iface;
            mode = "0600";
          };
        })
        allIfaces))
      # Клиентские конфиги
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

    # systemd-сервисы
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
              ExecStart = "${(pkgs.unstable.amneziawg-tools or pkgs.amneziawg-tools)}/bin/awg-quick up /etc/amneziawg/${iface.name}.conf";
              ExecStop = "${(pkgs.unstable.amneziawg-tools or pkgs.amneziawg-tools)}/bin/awg-quick down /etc/amneziawg/${iface.name}.conf";
            };
          };
        })
        allIfaces))
    ];

    # Firewall: по умолчанию открываем UDP-порты всех интерфейсов, TCP нет
    networking.firewall = {
      enable = true;
      allowedUDPPorts = map (i: i.port) allIfaces;
      allowedTCPPorts = [];
      checkReversePath = "loose";
    };
  };
}
