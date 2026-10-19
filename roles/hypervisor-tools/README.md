# Hypervisor Tools Role

This role provides utility scripts for managing the hypervisor environment. The scripts are installed to a directory on PATH (default: `/usr/local/bin/hypervisor-tools`) without the `.sh` extension.

## Scripts

### create-qcow2-disk

A generic script for creating and formatting qcow2 disk images.

**Usage:**
```bash
create-qcow2-disk <path> <label> <size>
```

**Example:**
```bash
# Create a 1GB disk for website data
create-qcow2-disk /var/kvm/images/website-data.qcow2 website 1G

# Create a 10GB disk for database
create-qcow2-disk /var/kvm/images/db-data.qcow2 dbdata 10G
```

**Features:**
- Creates qcow2 disk image at specified path
- Formats with ext4 filesystem
- Sets the specified label
- Bails out if image already exists
- Must be run as root (no sudo in script)
- Uses qemu-nbd for formatting without mounting
- Requires formatting tools and a free NBD device; never reports an unformatted image as success
- Disconnects its NBD attachment on errors; leaves partial images for inspection
- Serializes its own operations with `/run/lock/server-configuration-nbd.lock`
- Leaves the shared NBD kernel module loaded

**Requirements:**
- qemu-img
- qemu-nbd
- nbd kernel module
- ext4 filesystem tools
- flock (util-linux)

**Offline checks:**
```bash
bash -n roles/hypervisor-tools/scripts/create-qcow2-disk
python3 roles/hypervisor-tools/tests/test-create-qcow2-disk.py
```

Tests mock disk commands and device paths; they never format real devices.

### set-qcow2-password

Mounts an **offline**, whole-filesystem QCOW2 keys disk and atomically writes a
mode-0600 password hash for NixOS. It does not edit `/etc/shadow` or a root image.

**Usage:**
```bash
sudo set-qcow2-password /var/kvm/images/website-keys.qcow2 tarn
```

This prompts for the password twice and writes `/tarn-password` inside the image.
Passwords are piped to OpenSSL, never passed as command-line arguments. Existing
hashes survive password mismatch or hashing failure.

Shut down every VM using the image first. The helper checks active system-libvirt
domains (including backing stores) and keeps QEMU's exclusive image locking
enabled to reject other writers. Never use this with tools that bypass image
locking. It shares the disk creator's NBD lock, unmounts before disconnecting,
and leaves the device attached for manual recovery if unmount fails.

Requires root, system-libvirt access (`virsh`), Python 3, QEMU NBD, OpenSSL,
util-linux, coreutils and the NBD module. Only whole-filesystem images are
supported, not partitioned VM root disks. The helper leaves the NBD module loaded.

**Offline checks:**
```bash
bash -n roles/hypervisor-tools/scripts/set-qcow2-password
python3 roles/hypervisor-tools/tests/test-set-qcow2-password.py
```

## Target

This role is targeted at Debian-based systems.
