# Hypervisor

The hypervisor is a physical server hosted by Hetzner. It uses KVM/qemu to host
virtual machines.

Netfilter rules defined as custom `ufw` rules forward traffic intended for the
virtual machines to a bridge used by the virtual machines.
