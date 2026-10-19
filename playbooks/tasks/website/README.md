# Update tarnbarford.net content

From the repository root:

```sh
ansible-playbook playbooks/tasks/website/update.yml
```

Requires Ansible, the repository inventory/Vault configuration, and SSH access
with privilege escalation to the `tarnbarford` guest.

The playbook starts the guest's existing `website-update` systemd service. That
service fetches the website generator and posts, installs Python dependencies,
regenerates the site, and copies the output to the configured web root. The same
service also runs on a timer. If it is already running, starting it does not queue
a second update.

This updates content only; it does not rebuild or replace the VM image.

## VM rebuilds

See the [website role documentation](../../../roles/services/website/README.md)
for builder configuration and persistent disks. The current `build-and-deploy`
script uses `virsh destroy` when the VM is running; it is not a graceful shutdown
workflow. No rebuild wrapper is provided here. Review shutdown and recovery
procedures before using that script.
