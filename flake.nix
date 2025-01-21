{
  description = "Amnezia WG Nix Library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    defaultPackage.x86_64-linux = import ./default.nix {
      inherit (nixpkgs) lib pkgs;
    };
  };
}
