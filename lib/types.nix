{lib, ...}: {
  # 1) Описывает "network" (address, allowedNetworks и т.д.)
  amneziaWgNetworkType = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP/Mask (CIDR) для пира на данном интерфейсе (например 10.0.0.2/32).";
      };
      allowedNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Список AllowedIPs (помимо address), например ['192.168.0.0/24'].";
        default = [];
      };
      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Endpoint (host:port). Может быть null, если пиру не нужен Endpoint.";
        default = null;
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        description = "Keepalive в секундах, по умолчанию 25.";
        default = 25;
      };
    };
  };

  # 2) Описывает сам интерфейс (серверная сторона)
  amneziaWgInterfaceType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя интерфейса WireGuard (например 'awg0').";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "CIDR-адрес интерфейса (например '10.0.0.1/24').";
      };
      port = lib.mkOption {
        type = lib.types.int;
        description = "Порт (UDP) для этого интерфейса (например 51820).";
      };
      mtu = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        description = "MTU (необязательно).";
        default = null;
      };
    };
  };

  # 3) Peer (клиент, другой узел) — ссылается на amneziaWgNetworkType
  amneziaWgPeerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Идентификатор пира (произвольная строка).";
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Публичный ключ пира.";
      };
      privateKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Приватный ключ пира (если нужно генерировать клиентские конфиги).";
        default = null;
      };
      networks = lib.mkOption {
        type = lib.types.attrsOf amneziaWgNetworkType;
        description = ''
          Мапа ifaceName -> {
            address = "10.0.0.2/32";
            allowedNetworks = [...];
            endpoint = "...:51820";
            persistentKeepalive = 25;
          }
        '';
      };
    };
  };
}
