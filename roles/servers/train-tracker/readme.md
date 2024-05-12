Install the virtual machine

```
virt-install \
  --name train-tracker \
  --network bridge=virbr0 \
  --network bridge=br0 \
  --disk /var/kvm/images/train-tracker.qcow2 \
  --vcpu 1 \
  --memory 1096 \
  --os-variant generic \
  --console pty,target_type=virtio \
  --serial pty \
  --graphics none \
  --noautoconsole \
  --import
```

Update just the train-track input

```
cd /etc/nixos
nix flake lock --update-input trains
nixos-rebuild switch --flake "/etc/nixos#nixos"
```

Run manually on the server

```
export HTML_PATH=/var/www/trains/ 
export DATABASE_PATH=/var/lib/train-tracker/trains.db
export TOKEN_PATH=/var/lib/train-tracker/token.json
train-tracker
```
