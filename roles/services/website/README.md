# tarnbarford.net

## ACPI and existing VM migration

The domain template enables ACPI/APIC and pins the observed `pc-i440fx-10.0`
machine and NIC PCI slots 2/3. Website inventory therefore uses `ens2`/`ens3`
instead of `enp0s2`/`enp0s3`.

These source changes do **not** update the running VM. Do not apply the domain
XML alone or reboot with a guest image that still uses the old interface names.
Schedule a coordinated XML/root-image migration with serial-console access:

1. Securely save the actual inactive XML and a root-image recovery copy. Preserve
   UUID, MACs, PCI addresses and all five disk mappings.
2. Build the updated guest image before downtime and verify console credentials.
3. Stop gracefully and require libvirt `shut off` before offline disk access.
   Missing ACPI may leave a halted VM; pause for explicit recovery approval in
   that case. The current builder's automatic `virsh destroy` is **not** a safe
   migration/shutdown procedure.
4. Amend the saved actual XML with ACPI/APIC and replace only the root image as
   one maintenance operation; do not redefine blindly from the template.
5. Verify NIC names through the console, IPv4/IPv6 web access, persistent mounts,
   the content update service, and clean poweroff/start. Rollback needs a matching
   XML/root-image pair, without rolling back current persistent website/keys data.

Offline template regression (requires Python and Jinja2):

```sh
python3 roles/services/website/tests/check-acpi.py
```

## Quick Start

Before installing the VM, you need to create, format, and label all the qcow2 disks:

```bash
# Create and format all disks using the hypervisor-tools script
create-qcow2-disk /var/kvm/images/website-logs.qcow2 logs 1G
create-qcow2-disk /var/kvm/images/website-certificates.qcow2 certificates 1G
create-qcow2-disk /var/kvm/images/website-keys.qcow2 keys 1G
create-qcow2-disk /var/kvm/images/website-website.qcow2 website 1G
```

Before first boot, set the administrator's password on the offline keys disk:

```bash
sudo set-qcow2-password /var/kvm/images/website-keys.qcow2 tarn
```

The guest reads `/keys/tarn-password` through NixOS `hashedPasswordFile` during
activation. `/keys` is mounted in the initrd (`neededForBoot = true`) so the hash
is available before user activation. The disk is therefore boot-critical; a
missing/broken keys disk requires console/initrd recovery, not a fallback to an
unprotected administrator account. No password hash is embedded in the image.

For later password changes, gracefully stop the VM before using the helper and
boot it afterward. Never mount its keys image while the VM is running. Password
SSH login remains disabled; the password is for console/sudo access.

Then install the VM by running the build script on the hypervisor:

```bash
cd /home/tarn/builders/website
./build-and-deploy
```

This will build the NixOS image and define the VM with all disks attached.

## Password checks

From the repository's Nix development environment:

```bash
python3 roles/services/website/tests/check-password.py
python3 roles/hypervisor-tools/tests/test-set-qcow2-password.py
```

The first check evaluates synthetic guest/storage settings with the repository's
pinned Nixpkgs; it does not evaluate all unstable website service options. The
helper tests mock every VM/disk/mount operation. These are not a real-device or
boot integration test; verify boot and sudo on a disposable guest before deployment.
