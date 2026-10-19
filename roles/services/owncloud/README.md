# ownCloud Infinite Scale - Flake Configuration

Modern Nix flake-based deployment for ownCloud Infinite Scale (OCIS) on NixOS.

## ACPI and existing VM migration

The `ocis` domain template enables ACPI/APIC and pins the observed
`pc-i440fx-10.0` machine and NIC PCI slots 2/3. With ACPI, the guest network
configuration uses `ens2`/`ens3`, not the previous `enp0s2`/`enp0s3`.

These source changes do **not** fix an already-running VM. Do not apply the
role's domain-definition task alone or reboot with mismatched XML and image.
For an existing VM, schedule downtime and prepare a coordinated migration:

1. Save the actual inactive XML and a root-image recovery copy securely; retain
   UUID, MACs, PCI addresses and every persistent disk mapping.
2. Build the updated guest image before stopping the VM. Arrange serial-console
   access and working console credentials first.
3. Shut down gracefully and verify libvirt reports `shut off` before any offline
   disk access. If the guest only halts, stop and request explicit recovery
   approval; do not automatically use `virsh destroy`.
4. Amend the saved actual XML with ACPI/APIC and replace only the root image as
   one maintenance operation. Do not redefine from this template blindly.
5. Verify actual NIC names through the console, both address families, services,
   and a clean poweroff/start. Rollback must restore a matching XML/root pair;
   preserve current persistent data.

Offline regression check (requires Python and Jinja2):

```sh
python3 roles/services/owncloud/tests/check-acpi.py
```

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
