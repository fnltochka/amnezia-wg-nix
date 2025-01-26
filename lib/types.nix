{lib, ...}: {
  amneziaWgNetworkType = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP/Mask (CIDR) для интерфейса Amnezia WG.";
      };
      allowedNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Список разрешённых подсетей (AllowedIPs).";
        default = [];
      };
      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Endpoint для подключения.";
        default = null;
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        description = "Keepalive в секундах.";
        default = 25;
      };
    };
  };

  amneziaWgInterfaceType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя интерфейса (например, awg0).";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP/Mask (CIDR) для интерфейса (например, 10.0.0.1/24).";
      };
      port = lib.mkOption {
        type = lib.types.int;
        description = "Порт (UDP).";
      };
      mtu = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        description = "Опциональный MTU.";
        default = null;
      };
    };
  };

  amneziaWgPeerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя пира (идентификатор).";
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Публичный ключ пира.";
      };
      privateKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Приватный ключ (опционально).";
        default = null;
      };
      networks = lib.mkOption {
        type = lib.types.attrsOf (import ./. {}).amneziaWgNetworkType;
        description = "Сети (address, endpoint, allowedNetworks) для каждого интерфейса.";
      };
    };
  };
}
