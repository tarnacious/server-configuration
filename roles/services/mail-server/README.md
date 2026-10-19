# Mail server

Ansible renders a production NixOS mail VM builder on the hypervisor.
Postfix, Dovecot and Rspamd provide SMTP/25, submission/587 and IMAPS/993.
Certificates are managed on the guest.

## Configuration

`roles/services/mail-server/` contains:

```text
templates/nixos/  Nix templates: guest, mail policy, accounts and flake
files/nixos/      Pinned flake.lock (copied unchanged)
files/scripts/    Build, deploy, bootstrap and disk verification tools
templates/        Libvirt XML and hypervisor disk metadata
defaults/main.yml  Hypervisor paths, UUID and disk sizes
tests/             Render/evaluation checks and mocked deployment tests
```

All `.nix` files are Ansible templates, rendered directly into the builder's
`nixos/` directory. `guest.nix.j2` contains inventory-backed network and SSH
settings; `mail.nix.j2` contains mail identity and service policy. There is no
separate inventory Nix module or generated JSON service configuration.
`accounts.nix.j2` maps the `mail_server_accounts` inventory list. Production account
settings are stored together in the Vault-encrypted file
`inventory/host_vars/hypervisor/accounts.yml`. Edit it using `ansible-vault edit`
from the repository root (the configured `scripts/password` supplies the key).
Each entry has `address`, optional `aliases` (a list), `hashedPasswordFile`,
`quota` (a string), and `sendOnly` (a boolean). Hash-file paths must be under
`/keys/accounts/` and end in `.hash`; actual password hashes and private keys stay
on `/keys`, never in Git or the Nix store.

Vault protects the inventory in Git, not the rendered metadata: account addresses,
aliases, quotas and hash-file paths still enter the builder and Nix store. Tests
use a separate synthetic account list and do not need the production Vault key.

The role expects flat `mail_server_*` variables on the host running it.
Production inputs live in the **Mail server VM configuration** section of
`inventory/host_vars/hypervisor/main.yml`:
- `mail_server_hostname`, `mail_server_fqdn`, `mail_server_ipv4` and `mail_server_ipv6`.
- `mail_server_ipv4_*` / `mail_server_ipv6_*` interface, prefix, gateway, MAC and bridge settings.
- `mail_server_nameservers`, `mail_server_domains`, `mail_server_system_domain`
  and `mail_server_acme_email`.
- `mail_server_authorized_keys`: multiline public SSH keys, not private keys.

Inventory aliases shared addresses, gateways and administrator keys where
appropriate; the role itself does not look up other hosts or shared variables.
Preserve the production hardware values when editing: PCI slots in the XML
determine interface names.
Render before evaluating/building: the templates are not a standalone flake.
Rendering removes the obsolete mixed `source/` directory, old `admin.pub` and
legacy `inventory.nix` module;
render-only checks never modify live disks.

## Build and deploy

There is no dedicated production mail playbook. Include this role in a
hypervisor workflow when rendering is needed; it only installs the builder and
does not build or deploy. `tests/render.yml` is a local test fixture, not a
production entry point.

After rendering, run the operator scripts on the hypervisor. Build as the
unprivileged builder user; deploy requires root/sudo. Normal deployment never
creates persistent disks:

```sh
cd /home/tarn/builders/mail-production
./build
sudo ./deploy --check  # optional, no downtime
sudo ./deploy
```

Only `nixos/` enters the image. Scripts, XML, `host.json`, build manifests and result
links remain outside it. Deploy rejects stale builds/unexpected disk mappings,
gracefully stops the VM, replaces only root and restarts. Never force-stop mail.

## Storage and bootstrap

All disks are under `/var/kvm/images/mail-server/`:

| Image | Mount | Contents |
| --- | --- | --- |
| `root.qcow2` | `/` | Replaceable system |
| `keys.qcow2` | `/keys` | Account/admin hashes, SSH/DKIM keys |
| `data.qcow2` | `/var/vmail` | Mailboxes |
| `state.qcow2` | `/var/lib` | Mail queue, certificates, filter state |
| `logs.qcow2` | `/var/log` | Logs |

For **new empty storage only**, render and build, then run `./bootstrap` on the
hypervisor. It refuses an existing domain/UUID/directory, creates five disks and
defines the VM without starting it. Provision private account/admin hashes and
production DKIM keys on `/keys` before first boot. Bootstrap is not an update or
backup restore command.

Deploy preserves the four state disks and keeps one `root.previous.qcow2`.
That is not a state backup or a guarantee that software/schema downgrades are safe.
Missing persistent mounts prevent mail services starting.

## Checks and maintenance

```sh
bash roles/services/mail-server/tests/check.sh
ANSIBLE_BECOME_ASK_PASS=False ansible mail-server --become -m raw -a 'postqueue -p'
ANSIBLE_BECOME_ASK_PASS=False ansible mail-server --become -m raw -a 'systemctl --failed'
```

Tests render/evaluate without booting or contacting production; deployment tests
use mocks. Synthetic inventory values check that addresses, gateways, DNS,
identity, mail domains, ACME contact, administrator keys and VM NICs reach the
rendered configuration rather than falling back to production constants. There is no local VM framework. Inspect logs, queue and disk/inode
capacity; do not blanket-delete the queue. Keep password changes persistent on
`/keys`. Review pinned updates and state compatibility before deployment.

**Status:** refactored configuration matches the previous production accounts,
network, storage, SSH/DKIM/TLS and mail policy. Migration switches were replaced by
declarative public ports. This refactor has not been deployed live. Current-state
backup/restore verification remains separate; deleted migration recovery copies
are not available backups.
