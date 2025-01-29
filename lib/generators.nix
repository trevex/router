{ inputs, mylib, system, flake, ... }:
with mylib;
{
    mkFormat = format: modules: inputs.nixos-generators.nixosGenerate {
      inherit system format;
      specialArgs = { inherit inputs system flake; };
      modules = (mapModulesRec' (toString ../modules) import) ++ [{
        system.stateVersion = "24.11";
      }] ++ modules;
    };
}
