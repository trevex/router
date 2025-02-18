{ inputs, lib, pkgs, system, flake, ... }:

let
  inherit (lib) makeExtensible attrValues foldr;
  inherit (modules) mapModules;

  modules = import ./modules.nix {
    inherit lib;
    self.attrs = import ./attrs.nix { inherit lib; self = { }; };
  };

  mylib = makeExtensible (self:
    with self; mapModules ./.
      (file: import file { inherit self lib pkgs inputs system flake; mylib = self; }));
in
mylib.extend
  (self: super:
    foldr (a: b: a // b) { } (attrValues super))
