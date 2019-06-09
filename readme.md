## Server Configuration

This is the ansible configuration for my personal servers. The inventory and
secrets are not included in this repository.

## Servers

The servers currently include:

* [tarnbarford.net](https://tarnbarford.net) - my personal website
* [debugproxy.com](https://debugproxy.com) - a hosted http/https proxy service
* [bridgesacrossborders.net](https://bridgesacrossborders.net) - a website I host
* [owncloud.tarnbarford.net](https://owncloud.tarnbarford.net) - private owncloud server
* [icinga.tarnbarford.net](https://icinga.tarnbarford.net) - monitoring and alerts (icinga)
* [monitoring.tarnbarford.net](https://monitoring.tarnbarford.net) - monitoring (munin)
* mail.tarnbarford.net - public mail server and smtp relay (postfix, dovecot, spamassive, opendkim, opendmarc)
* ns1.tarnbarford.net - name server (bind9)
* ns2.tarnbarford.net - name server (bind9)
* backup system (bareos)
* root server that hosts most of the servers (KVM)

## Running playbooks

With Python 3.3 and above a virtual environment can be setup and ansible
installed in it like this.

```
python -m venv .
./bin/pip install -r requirements.txt
````

Playbooks describe indivual servers state. All playbooks expect some
configuration values via group_var or host_vars and a server described in the
inventory, these are not included in this repository.

```
./bin/ansible-playbook playbooks/tarnbarford.yml
```
