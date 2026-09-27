# Website VM Setup - Hypervisor Instructions

This file is on the hypervisor at: `/home/tarn/builders/website/README.md`

## Before Running the Build Script

You must manually create, format, and label all qcow2 disk images:

```bash
# Create and format all disks (requires root)
sudo create-qcow2-disk /var/kvm/images/website-logs.qcow2 logs 1G
sudo create-qcow2-disk /var/kvm/images/website-certificates.qcow2 certificates 1G
sudo create-qcow2-disk /var/kvm/images/website-keys.qcow2 keys 1G
sudo create-qcow2-disk /var/kvm/images/website-website.qcow2 website 1G
```

## Install the VM

Once all disks are created, run the build script from this directory:

```bash
cd /home/tarn/builders/website
./build-and-deploy
```

This will:
1. Build the NixOS VM image
2. Define the VM in libvirt with all disks attached

## Start the VM

```bash
virsh start website
```

## Notes

- The `create-qcow2-disk` script is provided by the hypervisor-tools role
- All disks must exist before running build-and-deploy
- The website disk (1G) is mounted at `/var/www/tarnbarford.net` in the VM
- Website files persist across rebuilds on this separate disk
