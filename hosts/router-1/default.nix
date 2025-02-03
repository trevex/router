{ lib, pkgs, config, ... }:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # Tweak to use correct tty
  boot.kernelParams = [ "console=tty0" ];

  boot.loader.systemd-boot.enable = true;
  # no need to set devices, disko will add all devices that have a EF02 partition to the list already

  # Make sure to select correct disk
  disko.devices.disk.main.device = "/dev/sda";

  services.tailscale.enable = true;

  my.user = "router-1";

  my.openssh = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
    ];
  };

  my.router = {
    enable = true;
    wanIf = "enp1s0";
    lanIf = "enp3s0";
    lanAddress = "fd00:cafe::2/64";
    vipAddress = "fd00:cafe::1/64";
    vipPriority = 40;
    raPrefix = "fd00:cafe::/64";
  };

  # some utility packages to debug things...
  environment.systemPackages = with pkgs; [
    vim
    git
    ripgrep
    curl
    moreutils
    unzip
    htop
    fd
    jq
  ];
}
