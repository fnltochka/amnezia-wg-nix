{
  config,
  pkgs,
  lib,
  ...
}:
import ./lib/amnezia-wg.nix {
  inherit config pkgs lib;
}
