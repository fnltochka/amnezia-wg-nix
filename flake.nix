{
  description = "Amnezia WG Nix Library";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    defaultPackage.${system} = import ./default.nix {
      inherit pkgs;
      lib = pkgs.lib;
    };
  };
}
