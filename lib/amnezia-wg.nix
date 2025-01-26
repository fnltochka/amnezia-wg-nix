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
  #### Описание опций ####
  options.networking.amnezia-wg = {
    exports = lib.mkOption {
      type = lib.types.submodule {
        options = {
          privateKey = lib.mkOption {
            type = lib.types.str;
            description = "Приватный ключ узла.";
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Публичный ключ узла.";
          };
          publicIP = lib.mkOption {
            type = lib.types.str;
            description = "Публичный IP-адрес узла.";
          };
          interfaces = lib.mkOption {
            type = lib.types.listOf (import ./types.nix {inherit lib;}).amneziaWgInterfaceType;
            description = "Список интерфейсов.";
            default = [];
          };
          peers = lib.mkOption {
            type = lib.types.attrsOf (import ./types.nix {inherit lib;}).amneziaWgPeerType;
            description = "Список пиров (по имени).";
            default = {};
          };
        };
      };
      description = "Экспорты Amnezia WG.";
    };

    # Подготовленный список интерфейсов для внутреннего использования (после обработки)
    processedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = interfacesLib.mkAmneziaWgInterfaces cfg.exports.interfaces;
    };
  };

  #### Реализация ####
  config = let
    allIfaces = cfg.processedInterfaces;
  in {
    # Пакеты
    environment.systemPackages = with pkgs; [
      unstable.amneziawg-tools
      iptables
      iproute2
      bash
    ];

    boot.extraModulePackages = [
      config.boot.kernelPackages.amneziawg
    ];
    boot.kernelModules = ["amneziawg"];

    # Генерация конфигов
    environment.etc = lib.mkMerge [
      # Сохраняем private.key / public.key
      {
        "amneziawg/private.key".text = cfg.exports.privateKey;
        "amneziawg/public.key".text = cfg.exports.publicKey;
      }
      # Серверная конфигурация для каждого iface
      (builtins.listToAttrs (map (iface: {
          name = "amneziawg/${iface.name}.conf";
          value = {
            text = configLib.generateServerConfig iface;
            mode = "0600";
          };
        })
        allIfaces))
      # Клиентские конфиги для каждого p2p
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

    # Запуск сервисов
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
              ExecStart = "${pkgs.unstable.amneziawg-tools}/bin/awg-quick up /etc/amneziawg/${iface.name}.conf";
              ExecStop = "${pkgs.unstable.amneziawg-tools}/bin/awg-quick down /etc/amneziawg/${iface.name}.conf";
            };
          };
        })
        allIfaces))
    ];

    # Firewall — открываем порты
    networking.firewall = {
      enable = true;
      allowedUDPPorts = map (i: i.port) allIfaces;
      allowedTCPPorts = [];
      checkReversePath = "loose";
    };
  };
}
