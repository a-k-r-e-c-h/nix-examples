{ nixpkgsSource ? null }:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource; localFiles = true; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  appPackage = nixpkgs.appPackage.override { inherit release; };
in
  pkgs.mkShell {
    inputsFrom = [ appPackage ];
    src = null;
  }
