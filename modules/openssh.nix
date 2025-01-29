{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.my.openssh;
in
{
  options = {
    my.openssh = {
      enable = mkEnableOption "OpenSSH";
      authorizedKeys = mkOption {
        type = types.listOf types.singleLineStr;
        default = [];
        description = ''
          A list of verbatim OpenSSH public keys that should be added to the
          user's authorized keys. The keys are added to a file that the SSH
          daemon reads in addition to the the user's authorized_keys file.
          You can combine the `keys` and
          `keyFiles` options.
          Warning: If you are using `NixOps` then don't use this
          option since it will replace the key required for deployment via ssh.
        '';
        example = [
          "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
          "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
        ];
      };
    };
  };
  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 22 ];
    };

    services.openssh = {
      enable = true;
      # require public key authentication for better security
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    users.users."${config.my.user}".openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}

