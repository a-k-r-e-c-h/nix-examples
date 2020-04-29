{
  nixpkgsSource ? null,
  localFiles ? true,
  clientLocally ? true
}:

let
  nixpkgs = import ./nixpkgs.nix { inherit nixpkgsSource localFiles; };
  pkgs = nixpkgs.pkgs;
  lib = nixpkgs.lib;
  deploymentNodes = import ./cd.nix {
    inherit nixpkgsSource localFiles clientLocally;
  };
in
  {

    network.description = "Network deployed to NixOS";

    server = {

      imports = [ deploymentNodes.server ];

      server = {
        deployment.targetHost = "1.2.3.4";
      };
    };

    client = {

      imports = [ deploymentNodes.client ];

      server = {
        deployment.targetHost = "1.2.3.5";
      };
    };

  }
