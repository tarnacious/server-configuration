## My Dell XPS13 laptop configuration


Updating the system,

    nix flake update
    nixos-rebuild switch --flake "/etc/nixos#nixos"

Wrireguard tunnel

    systemctl start wg-quick-wg0
    systemctl status wg-quick-wg0
    systemctl stop wg-quick-wg0

Currently the cachix configuration isn't conifigured in this role.

    cachix use cuda-maintainers
