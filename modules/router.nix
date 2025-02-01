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
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.${cfg.lanIf}.accept_ra" = false;
    };

    networking = {
      firewall.enable = false; # we are using nftables
      useDHCP = false; # we are using networkd

      nftables = {
        enable = true;
        ruleset = ''
          table ip filter {
            chain input {
              type filter hook input priority 0; policy drop;

              iifname lo accept comment "Allow connections from loopback"
              iifname { "${cfg.lanIf}" } accept comment "Allow local network to access the router"
              iifname "${cfg.wanIf}" ct state { established, related } accept comment "Allow established traffic"
              iifname "${cfg.wanIf}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
              tcp dport {ssh} accept comment "Allow SSH connections to the router"
              iifname "${cfg.wanIf}" counter drop comment "Drop all other unsolicited traffic from wan"
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
              iifname { "${cfg.lanIf}" } oifname { "${cfg.wanIf}" } accept comment "Allow trusted LAN to WAN"
              iifname { "${cfg.wanIf}" } oifname { "${cfg.lanIf}" } ct state established, related accept comment "Allow established back to LANs"
            }
          }

          table ip nat {
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              oifname "${cfg.wanIf}" masquerade
            }
          }

          table ip6 filter {
            chain input {
              type filter hook input priority 0; policy drop;
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
            }
          }
        '';
      };

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

    # IPv6 RA
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
            RDNSS ${builtins.elemAt (lib.splitString "/" cfg.vipAddress ) 0}{
                AdvRDNSSLifetime 3600;
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

    # DHCPv6
    services.kea.ctrl-agent.enable = false;
    services.kea.dhcp6 = {
      enable = true;
      settings = {
        interfaces-config = {
          interfaces = [ cfg.lanIf ];
        };
        option-data = [
          {
            name = "sntp-servers";
            data = "${builtins.elemAt (lib.splitString "/" cfg.vipAddress) 0}";
          }
          {
            name = "dns-servers";
            data = "${builtins.elemAt (lib.splitString "/" cfg.vipAddress) 0}";
          }
        ];
        lease-database = {
          type = "memfile";
        };
      };
    };

    # NTP
    services.chrony = {
      enable = true;
      extraConfig = ''
        allow ${cfg.raPrefix}
      '';
    };

    # DNS
    services.coredns = {
      enable = true;
      config = ''
        .:53 {
          forward . 8.8.8.8
          log
          errors
          cache
          dns64 {
            allow_ipv4
          }
        }
      '';
    };

  };
}

