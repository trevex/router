{ lib, pkgs, config, ... }:
let
  wanIf = "enp1s0";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # Tweak to use correct tty
  boot.kernelParams = [ "console=tty0" ];

  boot.loader.systemd-boot.enable = true;
  # no need to set devices, disko will add all devices that have a EF02 partition to the list already

  boot.kernel.sysctl = {
    "net.ipv4.ip_nonlocal_bind" = true;
  };

  # Make sure to select correct disk
  disko.devices.disk.main.device = "/dev/sda";

  my.user = "router-1";

  my.openssh = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
    ];
  };

  networking = {
    firewall = {
      enable = true;
      trustedInterfaces = [
        "wg0"
      ];
      pingLimit = "--limit 1/minute --limit-burst 5";
      allowedUDPPorts = [ 51820 ]; # wg
      allowedTCPPorts = [ 22 ];
    };
    useDHCP = false; # we are using networkd
  };

  systemd.network = {
    enable = true;
    networks."10-${wanIf}" = {
      matchConfig.Name = wanIf;
      networkConfig.DHCP = "yes";
    };
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
    dig
    tcpdump
    inetutils
    jq
  ];
}
