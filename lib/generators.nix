{ inputs, mylib, system, flake, pkgs, ... }:
with mylib;
{
    mkFormat = format: modules: inputs.nixos-generators.nixosGenerate {
      inherit system format;
      specialArgs = { inherit inputs system flake; };
      modules = (mapModulesRec' (toString ../modules) import) ++ [{
        system.stateVersion = "24.11";
        nix = {
          package = pkgs.nixVersions.stable;
          extraOptions = "experimental-features = nix-command flakes";
          settings = {
            allowed-users = [ "@wheel" ];
            trusted-users = [ "@wheel" ];
          };
        };
      }] ++ modules;
    };
}
