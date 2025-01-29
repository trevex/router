{ lib, pkgs, config, ... }:
{
  # Tweak to use correct tty
  boot.kernelParams = [ "console=tty0" ];

  my.user = "live";

  my.openssh = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
    ];
  };

  # some utility packages to debug things...
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    moreutils
  ];
}
