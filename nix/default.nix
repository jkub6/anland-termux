{ pkgs }:
let
  source = pkgs.fetchFromGitHub {
    owner = "jkub6";
    repo = "anland-termux";
    rev = "849c096ceb7d289bb42c2a1dfb89532cda93da84";
    hash = "sha256-ICAWloYgqE35QKsco3T248FHonHHf8L3yXSqN2hXIkw=";
  };
  anland = pkgs.callPackage ./package.nix { source = source + "/termux/anland"; };
  weston-anland = pkgs.callPackage ./weston.nix {};
  xwayland-anland = pkgs.callPackage ./xwayland.nix {};
  anland-session = pkgs.callPackage ./session.nix { inherit anland weston-anland xwayland-anland; };
in { inherit anland weston-anland xwayland-anland anland-session; }
