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

## Target

This role is targeted at Debian-based systems.
