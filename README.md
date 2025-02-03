# `router`

A NixOS-based HA router setup. WIP

## Installing

```bash
nix build .#install-iso
dd if=result/iso/nixos-24.11.20250128.2b4230b-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fdatasync

nixos-anywhere \
  --generate-hardware-config nixos-generate-config ./hosts/router-1/hardware-configuration.nix \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.x86_64-linux.kexec-installer-nixos-unstable-noninteractive)/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --flake .#nixosConfigurations.router-1.config --target-host root@192.168.1.136 \
  --no-substitute-on-destination --debug
nixos-anywhere \
  --generate-hardware-config nixos-generate-config ./hosts/router-2/hardware-configuration.nix \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.x86_64-linux.kexec-installer-nixos-unstable-noninteractive)/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --flake .#nixosConfigurations.router-2.config --target-host root@192.168.1.137 \
  --no-substitute-on-destination --debug
sudo tailscale up
```

## Notes

* IPv6 HA RA base network with dedicated prefix (VRRP + RADVD)
* Additional prefix for DHCPv6 which creates "translatable" IPs
* Use kea high availabiliy hook for DHCPv6
* As IPs are translatable, we can use SIIT to reach IPv4
* If we are natting the network now, we can use conntrackd (contrack-tools)
