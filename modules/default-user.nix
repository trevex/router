{ config, options, pkgs, lib, modulesPath, ... }:
with lib;
{
  options.my.user = mkOption {
    type = types.str;
    default = "";
  };

  config = mkIf (config.my.user != "") {
    users.users."${config.my.user}" = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/${config.my.user}";
      extraGroups = [ "wheel" "networkmanager" "input" "video" "dialout" "docker" ];
      hashedPassword = "$7$CU..../....darl3WJb9VjRQQ/4Z9sEj.$YFZjb2Cy7ODMLvfcvSm0TF1GbOWgrxf8dQtAHrEfXU8";
    };
    services.getty.autologinUser = "${config.my.user}";
    security.sudo.extraRules= [{
      users = [ "${config.my.user}" ];
      commands = [{
        command = "ALL" ;
        options = [ "NOPASSWD" ];
      }];
    }];

  };
}
