# Australia image (experimental; no production cutover)

This role renders **non-secret** NixOS configuration locally. Nix builds a pinned x86_64 DigitalOcean QCOW2 image with SSH, BIND, WireGuard service, firewall, NAT and filesystem growth. Nothing contacts the existing Australia VM or DigitalOcean during render/build/test. The pinned `flake.lock` is copied unchanged. See [background](../../docs/australia.md).

## Local use

Prerequisites: `ansible-core`, Nix with flakes enabled, QEMU (`qemu-system-x86_64`, `qemu-img`), gzip, KVM for boot testing; several GB of disk and 2 GB RAM. The renderer requires only `australia_wireguard_port` (non-secret number); `tests/local.yml` supplies 51194. Keep the workspace **outside** this repository and outside `/nix/store`.

```sh
roles/australia/scripts/render roles/australia/tests/local.yml /tmp/australia-local-test
roles/australia/scripts/test /tmp/australia-local-test
roles/australia/scripts/build roles/australia/tests/local.yml /tmp/australia-local-test
# Rebuild without rerendering:
roles/australia/scripts/build roles/australia/tests/local.yml /tmp/australia-local-test --build-only
roles/australia/scripts/vm start /tmp/australia-local-test
roles/australia/scripts/vm stop /tmp/australia-local-test
```

After editing a template rerun `render` (or `build` without `--build-only`). Artifact link: `$workspace.image/*.qcow2.gz`; local disk copy, console log and PID: `$workspace.vm/` (both outside the flake source). The synthetic test zone is `$workspace.test-zone`. Never put guest disks, secrets or runtime vars in the workspace: Nix copies its entire source into the store. `vm start` uses QEMU user networking, forwarding SSH only on 127.0.0.1:22220, monitor on 127.0.0.1:22221; it does **not** modify host networking. `vm stop` requests ACPI shutdown. The DigitalOcean profile expects its metadata endpoint for root SSH key installation: local QEMU boots but does **not** grant SSH access without a metadata emulator. Do not use production credentials to bootstrap a local test.

## Runtime boundary

Image contains no private key, no DNS instance addresses and no password. DO metadata installs root SSH *public* keys; password login and execution of Nix user-data are disabled. The DO NixOS profile uses its metadata agent, not cloud-init; compatibility with the current DO custom-image initialization policy **must be verified on a disposable Droplet before upload/cutover**. Host SSH keys/machine ID must be verified fresh on first boot.

BIND reads `/var/lib/australia/zones/db.tarnbarford.net` (root:named 0640); the VPN reads `/etc/wireguard/wg0.conf` (root:root 0600). Until those files exist the systemd services skip startup. `playbooks/tasks/australia/provision.yml` renders these on the target *after* its public IPs are known, checks the zone with `named-checkzone`, publishes it and restarts BIND / starts WireGuard. Runtime vars must provide `hosts` (the complete mapping required by `templates/db.tarnbarford.net.j2`, including `hosts.australia.ipv4/ipv6`), `wireguard_private_key`, `wireguard_address`, `wireguard_address6`, `wireguard_port` and `wireguard_peers` (name/public_key/allowed_ips). A monotonically increasing SOA serial is generated at provisioning time. **Only** supply private material in Vault/secured variables, not the render vars, flake, workspace, image, user data, arguments or logs. The playbook suppresses logging of the key-bearing task; protect Ansible temp files and the target's disk.

Provisioning is intentionally separate and requires explicit inventory, exact target, and runtime vars:

```sh
# Only after the disposable VM has working SSH and the runtime vars are prepared:
roles/australia/scripts/provision /path/to/test-inventory test-australia /path/to/vault-runtime-vars.yml
```

Pass an Ansible vault password using a protected `ANSIBLE_VAULT_PASSWORD_FILE` if necessary. The existing Debian playbook is not applicable. No upload/Droplet creation or production cutover script exists; do not treat a local boot as cloud readiness. Test DNS over UDP/TCP and both families, VPN handshake, forwarding, and metadata/SSH on a disposable Sydney Droplet before changing authoritative DNS or clients.

## Verification status

Synthetic Ansible render, Nix evaluation, `named-checkzone` on the rendered public zone, image build and QEMU boot/ACPI shutdown were run locally. QEMU boot reached the login prompt and started nftables; runtime DNS/VPN, SSH provisioning and DigitalOcean ConfigDrive/metadata have **not** been tested end-to-end. See the background document for the wider deployment plan.
