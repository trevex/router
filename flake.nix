{
  description = "router";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, deploy-rs, ... }@inputs:
    let
      overlays = [
      ];
    in
    flake-utils.lib.eachDefaultSystemPassThrough (system:
    let
        inherit (pkgs) mkShell;
        inherit (mylib) mkFormat mapModulesRec mapHosts;
        # create pkgs with overlays and access to unstable
        pkgs' = import nixpkgs-unstable { inherit system; };
        overlays = [(final: prev: {
          unstable = pkgs';
          my = self.packages."${system}";
        })];
        pkgs = import nixpkgs { inherit system overlays; };
        # let's create mylib
        lib = nixpkgs.lib;
        mylib = import ./lib { inherit pkgs inputs lib system; flake = self; };
      in
      rec {
        devShell.${system}.default = mkShell rec {
          name = "router";

          buildInputs = with pkgs; [
            nixos-anywhere
            deploy-rs
            rsync
          ];
        };

        packages.${system} = rec {
          install-iso = mkFormat "install-iso" [ ./hosts/install.nix ];
        };

        nixosModules = mapModulesRec ./modules import;
        nixosConfigurations = mapHosts ./hosts;

        deploy.nodes = {
          router-1 = {
            hostname = "192.168.1.136";
            profiles.system = {
              user = "root";
              sshUser = "router-1";
              fastConnection = true; # copy the whole closure instead of letting the node substitute
              path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.router-1;
              activationTimeout = 2400;
              confirmTimeout = 1200;
            };
          };
          router-2 = {
            hostname = "192.168.1.137";
            profiles.system = {
              user = "root";
              sshUser = "router-2";
              fastConnection = true; # copy the whole closure instead of letting the node substitute
              path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.router-2;
              activationTimeout = 2400;
              confirmTimeout = 1200;
            };
          };
        };

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      }
    );
}
