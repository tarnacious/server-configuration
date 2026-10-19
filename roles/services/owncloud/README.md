# ownCloud Infinite Scale - Flake Configuration

Modern Nix flake-based deployment for ownCloud Infinite Scale (OCIS) on NixOS.

## Quick Start

```bash
# Build the disk image
nix build .#owncloud-image

# The image will be at: ./result/nixos.qcow2

# Enter development shell
nix develop
```

## Configuration

Edit `configuration.nix` to customize:

- Network settings (IP addresses, gateways)
- OCIS configuration (address, port, URL, admin password)
- Caddy reverse proxy settings
- User accounts and SSH keys

## Customization

Override configuration using flake:

```nix
{
  inputs.owncloud.url = "path:roles/services/owncloud";
  outputs = { self, owncloud, ... }:
    let system = "x86_64-linux";
    in {
      nixosConfigurations.my-owncloud = owncloud.nixosConfigurations.owncloud.override {
        modules = [ { services.ocis.url = "https://cloud.my-domain.com"; } ];
      };
    };
}
```

## Nixpkgs Version

Change in `flake.nix`:

```nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # Stable
# or
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # Unstable
```

## Post-Deployment

After VM creation, format and label the disks:

```bash
sudo mkfs.ext4 -L logs /dev/vdb
sudo mkfs.ext4 -L certificates /dev/vdc
sudo mkfs.ext4 -L data /dev/vdd
```
