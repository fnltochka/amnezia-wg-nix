# Amnezia WG Nix Library

Amnezia WG Nix Library — модуль NixOS для настройки и управления VPN-сервисом Amnezia WG на ваших узлах.

## Возможности

- Простая настройка интерфейсов VPN
- Управление пирами и их конфигурациями
- Генерация клиентских и серверных конфигураций
- Интеграция с системой фаерволла

## Установка

### Добавление библиотеки в конфигурацию NixOS

```nix
{
  imports = [
    (import (builtins.fetchGit {
      url = "https://github.com/fnltochka/amnezia-wg-nix.git";
      rev = "main";
      sha256 = "0v...";
    }) {})
  ];

  networking.amnezia-wg = {
    exports = {
      privateKey = "ВАШ_ПРИВАТНЫЙ_КЛЮЧ";
      publicKey = "ВАШ_ПУБЛИЧНЫЙ_КЛЮЧ";
      publicIP = "ВАШ_PUBLIC_IP";
      interfaces = [
        {
          name = "awg0";
          address = "10.0.0.1/24";
          port = 51820;
        }
      ];
      peers = {
        node1 = {
          name = "node1";
          privateKey = "КЛЮЧ_ПИРА";
          publicKey = "ПУБЛИЧНЫЙ_КЛЮЧ_ПИРА";
          networks = {
            awg0 = {
              address = "10.0.0.2/32";
              allowedNetworks = [
                "10.0.0.0/24"
                "192.168.88.20/24"
              ];
            };
          };
        };
      };
    };
    interfaces = networking.amnezia-wg.exports.interfaces;
  };
}
```
