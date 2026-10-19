# Australia: DNS, VPN and experimental NixOS image

`australia` provides authoritative DNS for `tarnbarford.net` and a WireGuard VPN
endpoint. The existing Debian configuration and experimental NixOS image are
separate workflows. This document describes checked-in configuration, not a
fresh inspection of the running server.

## Existing Debian server

- [Server playbook](../playbooks/servers/australia.yml): hostname, packages,
  unattended upgrades, SSH, UFW, WireGuard and BIND.
- [Host variables](../inventory/host_vars/australia.yml): identity, vaulted become
  password and WireGuard settings/secrets.
- [Inventory](../inventory/hosts.yml) and
  [shared variables](../inventory/group_vars/all.yml): SSH target and service
  address mappings.

The [BIND role](../roles/bind/) renders and validates public and internal zone
files. Its checked-in `named.conf.local` declares only the public zone; do not
assume the internal zone is served merely because its file is installed.
Australia also supplies the public `ns2` address records.

The [VPN role](../roles/vpn/) configures `wg0`, enables forwarding, installs NAT
scripts and opens UDP/51194. Its NAT scripts assume the external interface is
`eth0`. The service task starts WireGuard but sets `enabled: false`, so this
playbook does not ensure VPN startup after reboot. Review deployed state before
changing either behavior.

The Debian server playbook changes a real server. Do not use it to render or
provision the experimental NixOS image.

## Experimental NixOS workflow

The [Australia role README](../roles/australia/README.md) is the operational
reference for prerequisites, scripts, inputs and artifact locations.

The role renders non-secret configuration locally and builds a pinned x86_64
DigitalOcean-profile QCOW2 image. The image configures SSH, BIND, WireGuard,
firewall, NAT and filesystem growth. Rendering, building and local checks do
not contact production or create DigitalOcean resources.

Ownership is split as follows:

| Component | Responsibility |
| --- | --- |
| Ansible renderer | Non-secret Nix configuration and unchanged pinned lockfile |
| NixOS | Guest packages, services, networking policy and image |
| Post-boot Ansible | Runtime WireGuard secrets and instance-specific DNS zone |
| Operator | Cloud upload, Droplet creation, verification and eventual cutover |

From the repository root, in an environment with the prerequisites listed in
the role README:

```sh
roles/australia/scripts/test /tmp/australia-local-test
roles/australia/scripts/build roles/australia/tests/local.yml /tmp/australia-local-test
roles/australia/scripts/vm start /tmp/australia-local-test
roles/australia/scripts/vm stop /tmp/australia-local-test
```

Keep the rendered workspace outside the repository. Image artifacts and VM
state are separate sibling paths, not files inside the Nix source. The local
QEMU wrapper uses user networking and loopback-only forwarded ports; it does
not modify host routing.

The DigitalOcean profile expects metadata to install root SSH public keys.
The default local QEMU setup does not emulate that endpoint, so reaching a
login prompt does not establish SSH or provisioning readiness.

## Runtime configuration and secrets

The guest reads:

- `/etc/wireguard/wg0.conf`: private VPN configuration, root-only.
- `/var/lib/australia/zones/db.tarnbarford.net`: instance-specific DNS zone.

Services skip startup while their runtime files are absent. The explicit
[provisioning playbook](../playbooks/tasks/australia/provision.yml) installs these
files after SSH and instance addresses are available; it validates the DNS zone
before publishing it. Use the role's `provision` wrapper with an explicit test
inventory, exact target and protected runtime variables, as documented in its
README.

The provisioner derives a serial from the current Unix timestamp. Compare it
with the deployed SOA serial before publication; do not assume a generated
serial is necessarily newer than existing DNS state.

Private keys belong in Vault or protected runtime inputs, never render vars,
flake sources, the Nix store, images, user data, command-line arguments or logs.
The image disables metadata-supplied root passwords and Nix user-data rebuilds.
It uses the NixOS DigitalOcean metadata agent, not cloud-init.

## Verification limits and deployment gates

The role README records successful synthetic render/evaluation, zone validation,
image build and local QEMU boot/ACPI shutdown. Runtime DNS/VPN, SSH provisioning
and DigitalOcean initialization have not been tested end-to-end. This document
adds no new runtime verification.

There is no upload, Droplet-creation or production-cutover tooling. Before using
the image for production:

1. Confirm compatibility with current DigitalOcean custom-image requirements,
   boot layout, metadata/bootstrap behavior and filesystem resizing.
2. Use a disposable Droplet to verify fresh SSH host keys/machine identity,
   administrative access and post-boot secret provisioning.
3. Test authoritative DNS over UDP/TCP and both IP families, plus VPN handshake,
   forwarding, NAT and external reachability.
4. Plan address changes, registrar/DNS updates, VPN-client changes and rollback.
   Australia is an advertised nameserver: do not remove the old server merely
   because a replacement image boots.

References: [DigitalOcean custom images](https://docs.digitalocean.com/products/custom-images/),
[image upload](https://docs.digitalocean.com/products/custom-images/how-to/upload/)
and [Droplet metadata](https://docs.digitalocean.com/products/droplets/how-to/access-metadata/).
