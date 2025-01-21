# Amnezia WG Nix Library

The Amnezia WG Nix Library is a NixOS module designed for configuring and managing the Amnezia WG VPN service on your nodes.

## Features

- **Simple VPN Interface Configuration:** Easily set up and manage VPN interfaces.
- **Peer Management:** Handle peers and their configurations seamlessly.
- **Configuration Generation:** Automatically generate client and server configurations.
- **Firewall Integration:** Integrates with the system firewall for enhanced security.

## Installation

### Adding the Library to Your NixOS Configuration

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
      privateKey = "YOUR_PRIVATE_KEY";
      publicKey = "YOUR_PUBLIC_KEY";
      publicIP = "YOUR_PUBLIC_IP";
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
          privateKey = "PEER_PRIVATE_KEY";
          publicKey = "PEER_PUBLIC_KEY";
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

## License

This project is licensed under the [MIT License](LICENSE).
