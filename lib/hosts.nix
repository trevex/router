{ lib, inputs, mylib, system, flake, pkgs, ... }:
with lib;
with mylib;
{
  mkHost = path: nixosSystem {
    inherit system;
    specialArgs = { inherit lib inputs system mylib flake; };
    modules = (mapModulesRec' (toString ../modules) import) ++ [
      inputs.disko.nixosModules.disko
      {
        system.stateVersion = "24.11";
        nixpkgs.pkgs = pkgs;
        networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
        nix = {
          package = pkgs.nixVersions.stable;
          extraOptions = "experimental-features = nix-command flakes";
          settings = {
            allowed-users = [ "@wheel" ];
            trusted-users = [ "@wheel" ];
          };
        };
      }
      (import path)
    ];
  };

  mapHosts = dir:
    mapModules dir
      (hostPath: mkHost hostPath);
}
