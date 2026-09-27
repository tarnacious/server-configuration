# tarnbarford.net

## Quick Start

Before installing the VM, you need to create, format, and label all the qcow2 disks:

```bash
# Create and format all disks using the hypervisor-tools script
create-qcow2-disk /var/kvm/images/website-logs.qcow2 logs 1G
create-qcow2-disk /var/kvm/images/website-certificates.qcow2 certificates 1G
create-qcow2-disk /var/kvm/images/website-keys.qcow2 keys 1G
create-qcow2-disk /var/kvm/images/website-website.qcow2 website 1G
```

Then install the VM by running the build script on the hypervisor:

```bash
cd /home/tarn/builders/website
./build-and-deploy
```

This will build the NixOS image and define the VM with all disks attached.
