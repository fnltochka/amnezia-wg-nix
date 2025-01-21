{lib, ...}: {
  amneziaWgNetworkType = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP адрес и маска подсети для интерфейса Amnezia WG";
      };
      allowedNetworks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Разрешенные подсети для Amnezia WG";
        default = [];
      };
      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Endpoint для подключения Amnezia WG";
        default = null;
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.int;
        description = "Интервал keepalive в секундах для Amnezia WG";
        default = 25;
      };
    };
  };

  amneziaWgInterfaceType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя интерфейса Amnezia WG";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP адрес и маска подсети для интерфейса Amnezia WG";
      };
      port = lib.mkOption {
        type = lib.types.int;
        description = "Порт для интерфейса Amnezia WG";
      };
      mtu = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        description = "MTU для интерфейса Amnezia WG";
        default = null;
      };
    };
  };

  amneziaWgPeerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Имя пира для Amnezia WG";
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Публичный ключ пира Amnezia WG";
      };
      privateKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Приватный ключ пира Amnezia WG (опционально, для генерации клиентской конфигурации)";
        default = null;
      };
      networks = lib.mkOption {
        type = lib.types.attrsOf amneziaWgNetworkType;
        description = "Конфигурация сетей для пира Amnezia WG";
      };
    };
  };
}
