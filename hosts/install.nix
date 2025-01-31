{ lib, pkgs, config, ... }:
{
  # Tweak to use correct tty
  boot.kernelParams = [ "console=tty0" ];

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcKW01TP/gVI1KaExyrOMnnj7HUQ58Pa40r4nKGVQ8f niklas.voss@gmail.com"
  ];

  services.fwupd.enable = true;

  # some utility packages to debug things...
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    moreutils
    smartmontools
  ];
}
