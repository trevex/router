{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.my.router;
in
{
  options = {
    my.router = {
      enable = mkEnableOption "Router";
      wanIf = mkOption {
        type = types.str;
        description = ''
          TODO
        '';
        example = "eth0";
      };
      lanIf = mkOption {
        type = types.str;
        description = ''
          TODO
        '';
        example = "eth1";
      };
      lanAddress = mkOption {
        type = types.str;
        description = ''
          TODO
        '';
        example = "fd00:dead:beef::2";
      };
      vipAddress = mkOption {
        type = types.str;
        description = ''
          TODO
        '';
        example = "fd00:dead:beef::1";
      };
      vipID = mkOption {
        type = types.int;
        default = 64;
        description = ''
          TODO
          '';
        example = 64;
      };
      vipPriority = mkOption {
        type = types.int;
        default = 20;
        description = ''
          TODO
          '';
        example = 20;
      };
      raPrefix = mkOption {
        type = types.str;
        description = ''
          TODO
          '';
        example = "fd00:cafe::/64";
      };
    };
  };
  config = mkIf cfg.enable {

    boot.kernel.sysctl = {
      "net.ipv4.ip_nonlocal_bind" = true;
    };

    networking = {
      firewall = {
        enable = true;
        trustedInterfaces = [
          "tailscale0"
        ];
        pingLimit = "--limit 1/minute --limit-burst 5";
        allowedUDPPorts = [ 51820 ]; # wg
        allowedTCPPorts = [ 22 ];

        extraCommands = ''
          # Allow VRRP and AH packets
          ip6tables -A nixos-fw -i ${cfg.lanIf} -p vrrp -j ACCEPT
          ip6tables -A nixos-fw -i ${cfg.lanIf} -p ah -j ACCEPT
        '';

        extraStopCommands = ''
          ip6tables -D nixos-fw -i ${cfg.lanIf} -p vrrp -j ACCEPT || true
          ip6tables -D nixos-fw -i ${cfg.lanIf} -p ah -j ACCEPT || true
        '';
      };
      useDHCP = false; # we are using networkd
    };

    systemd.network = {
      enable = true;
      networks = {
        "10-${cfg.wanIf}" = {
          matchConfig.Name = cfg.wanIf;
          networkConfig.DHCP = "yes";
          linkConfig.RequiredForOnline = "routable";
        };
        "10-${cfg.lanIf}" = {
          matchConfig.Name = cfg.lanIf;
          address = [
            cfg.lanAddress
          ];
          routes = [
            { Gateway = "fe80::1"; }
          ];
        };
      };
    };

    # https://fy.blackhats.net.au/blog/2018-11-01-high-available-radvd-on-linux/
    services.keepalived = {
      enable = true;

      extraGlobalDefs = ''
        vrrp_version 3
      '';

      extraConfig = ''
        vrrp_sync_group G1 {
          group {
           ipv6_${cfg.lanIf}
          }
        }

        vrrp_instance ipv6_${cfg.lanIf} {
           interface ${cfg.lanIf}
           virtual_router_id ${builtins.toString cfg.vipID}
           priority ${builtins.toString cfg.vipPriority}
           advert_int 1.0
           virtual_ipaddress {
             fe80::1:1
             ${cfg.vipAddress}
           }
           nopreempt
           garp_master_delay 1
        }
      '';
    };

    services.radvd = {
      enable = true;
      config = ''
        interface ${cfg.lanIf}
        {
            AdvSendAdvert on;
            MinRtrAdvInterval 30;
            MaxRtrAdvInterval 100;
            AdvRASrcAddress {
                fe80::1:1;
            };
            prefix ${cfg.raPrefix}
            {
                AdvOnLink on;
                AdvAutonomous on;
                AdvRouterAddr off;
            };
        };
      '';
    };

  };
}

