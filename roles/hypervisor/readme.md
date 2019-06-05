
apt-get update
apt-get upgrade

# create user tarn
# add to sudoers group
# add ssh authorized_keys

# As root
cd ~/
build_vm base_vm base_vm 0
virsh net-start default
create_domain vm-name

```
