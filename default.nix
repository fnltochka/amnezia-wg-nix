{
  lib,
  pkgs,
  ...
}:
import ./lib/amnezia-wg.nix {
  inherit lib pkgs;
}
