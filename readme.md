## System Configuration

This is the Ansible configuration for my personal computers, virtual machines
and servers. Sensitive data is encrypted with ansible-vault.

I use this project to configure my personal laptop, my work laptop, my
[personal website][1], my [owncloud][3], my mail server, a random Wordpress
[site][4] I host for a friend, some DNS name servers, a backup system, a
[monitoring][5] system, a physical server running most of my VMs and a couple
of VMs I use locally.

I find Ansible for my personal use-cases pretty perfect as it's only marginally
more effort than taking notes or writing bash scripts when manually configuring
systems and I find it significantly better than both when returning to those
systems months or years later. I've also found it to be very useful for
managing my laptops and development environments as I can install and configure
vim, git, tmux, gpg/ssh agents etc across different system with my personal
preferences.

## Installing Ansible

The Ansible version used should run on Python 3.3 and above.

On Debian-like systems it makes sense to install inside a Python virtual
environment or something similar.

```
python -m venv .
source ./bin/activate
```

For Nix environments there is configuration which can be used.

```
nix-shell
````

To install the packages on either system

```
pip install -r requirements.txt
```

## Secrets

Secrets in the inventory are encrypted with Ansible Vault. Ansible will try to
decrypt the required secrets when running playbooks using a password found
using the `pass` program with the key `vault/servers`.

Additionally there are two scripts `./scripts/encrypt` and `./scripts/decrypt`
which I use to encrypt and decrypt secrets in Vim.

# Running Playbooks

Playbooks are used to actually install and configure things. Generally
playbooks configure a single system.

```
ansible-playbook playbooks/tarnbarford.yml --ask-become-user
```

In most cases the `--ask-become-user` option is required to configure things as
the root user on the target system.


[1]: https://tarnbarford.net
[2]: https://debugproxy.com
[3]: https://bridgesacrossborders.net
[4]: https://owncloud.tarnbarford.net
[5]: https://icinga.tarnbarford.net
[6]: https://monitoring.tarnbarford.net
