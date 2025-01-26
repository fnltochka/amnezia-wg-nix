{lib, ...}: {
  ### 1) NetworkType — описывает подсети для конкретного интерфейса WireGuard
  amneziaWgNetworkType = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP/Mask (CIDR) для интерфейса Amnezia WG (например, 10.0.0.2/32).";
      };
      allowedNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Список разрешённых подсетей (AllowedIPs).";
        default = [];
      };
      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Endpoint для подключения (host:port). Может быть null.";
        default = null;
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        description = "Keepalive-интервал в секундах. По умолчанию 25.";
        default = 25;
      };
    };
  };

  ### 2) InterfaceType — описывает интерфейс WireGuard (серверная сторона)
  amneziaWgInterfaceType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя интерфейса (например, awg0).";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP/Mask (CIDR) для этого интерфейса (например, 10.0.0.1/24).";
      };
      port = lib.mkOption {
        type = lib.types.int;
        description = "UDP-порт, на котором будет слушать WireGuard.";
      };
      mtu = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        description = "MTU интерфейса (необязательный).";
        default = null;
      };
    };
  };

  ### 3) PeerType — описывает Peer (клиентскую/другую узловую конфигурацию)
  amneziaWgPeerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя пира (любая строка-идентификатор).";
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Публичный ключ пира.";
      };
      privateKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Приватный ключ пира (опционально, если нужно генерировать клиентские конфиги).";
        default = null;
      };
      networks = lib.mkOption {
        # Привязка к amneziaWgNetworkType
        type = lib.types.attrsOf amneziaWgNetworkType;
        description = ''
          Отображение: interfaceName -> {
            address = "10.0.0.2/32";
            allowedNetworks = ["10.0.0.0/24"];
            endpoint = "endpoint_ip:port";
            persistentKeepalive = 25;
          }.
        '';
      };
    };
  };
}
