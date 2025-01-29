# `router`

A NixOS-based HA router setup. WIP

## Installing

```bash
nix build .#live
dd if=result/iso/nixos.iso of/dev/sdX bs=4M status=progress conv=fdatasync
nixos-anywhere \
  --generate-hardware-config nixos-generate-config ./hosts/router-1/hardware-configuration.nix \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.x86_64-linux.kexec-installer-nixos-unstable-noninteractive)/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --flake .#nixosConfigurations.router-1.config --target-host live@192.168.1.136 \
  --no-substitute-on-destination --debug
```
